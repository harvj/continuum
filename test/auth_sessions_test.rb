ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
require "rails/test_help"
require "tmpdir"

if ENV["CONTINUUM_TEST_POSTGRES"] == "1"
  class AuthSessionsTest < ActionDispatch::IntegrationTest
    self.use_transactional_tests = false

    class Provider
      attr_accessor :active, :calls, :username, :eligible, :outage, :evidence_outage
      attr_reader :revoked

      def initialize(registration)
        @registration = registration
        @active = true
        @username = "jim"
        @eligible = %w[continuum-engine continuum muzeum]
        @calls = 0
      end

      def authorization_url(attempt)
        "#{ContinuumAuth::ISSUER}/authorize?#{URI.encode_www_form(state: attempt.state, redirect_uri: @registration.callback)}"
      end

      def exchange(code, _attempt)
        raise ContinuumAuth::Invalid unless code == "verified-test-code"

        @calls += 1
        ContinuumAuth::Identity.new("subject", "grant", 5.minutes.from_now)
      end

      def active?(grant, subject:)
        raise ContinuumAuth::Unavailable if outage

        active && grant == "grant" && subject == "subject"
      end

      def evidence(_grant, subject:)
        raise ContinuumAuth::Unavailable if evidence_outage

        ContinuumAuth::Evidence.new(username, eligible, 45.seconds.from_now) if subject == "subject"
      end

      def revoke(grant)
        raise ContinuumAuth::Unavailable if outage

        @revoked = grant
      end
    end

    setup do
      @config = Rails.application.config.x
      @previous = [@config.auth_registrations, @config.auth_provider, @config.shell_registry]
      @old_csrf = AuthSessionsController.allow_forgery_protection
      AuthSessionsController.allow_forgery_protection = true
      hosts = LandingController::SECTIONS.map { |section| "#{section}.harvj.com" }
      registrations = hosts.index_with { |host| { "client_id" => host, "client_secret" => "test-only" } }
      @config.auth_registrations = ContinuumAuth.registrations(registrations.to_json)
      @providers = @config.auth_registrations.transform_values { |registration| Provider.new(registration) }
      @config.auth_provider = ->(registration) { @providers.fetch(registration.host) }
      @root = Pathname(Dir.mktmpdir)
      @config.shell_registry = ShellRegistry.new(@root.join("registry.json").to_s)
      https!
      host! "network.harvj.com"
      ContinuumSession.delete_all
      ContinuumOidcAttempt.delete_all
    end

    teardown do
      @config.auth_registrations, @config.auth_provider, @config.shell_registry = @previous
      AuthSessionsController.allow_forgery_protection = @old_csrf
      FileUtils.remove_entry(@root)
    end

    test "all public hosts have deliberate host-local entry and no rendering-time login" do
      @providers.each_key do |host|
        host! host
        get "/"
        assert_response :ok
        assert_select "nav a", count: 3
        assert_select "header a[href='/login'], header [aria-label=Home], header details", count: 0
        get "/login", headers: { "Sec-Purpose" => "prefetch" }
        assert_response :no_content
        sign_in
        get "/"
        assert_select ".shell-session-name", text: "jim"
        assert_select ".shell-session-panel a[href='https://auth.harvj.com/account?client_id=#{host}']"
        assert_select ".shell-applications[hidden] li", count: 0
        assert_includes response.headers["Cache-Control"], "no-store"
      end
    end

    test "callbacks reject duplicate fields, unsolicited requests, cross-host use and replay" do
      get "/auth/callback", params: { code: "verified-test-code" }
      assert_response :bad_request
      state = begin_login
      get "/auth/callback?state=#{state}&state=#{state}&code=verified-test-code"
      assert_response :bad_request

      host! "library.harvj.com"
      callback(state)
      assert_response :bad_request
      host! "network.harvj.com"
      callback(state)
      assert_response :see_other
      callback(state)
      assert_response :bad_request
      assert_equal 1, @providers.fetch("network.harvj.com").calls
    end

    test "expired attempts and matched denials are terminal" do
      state = begin_login
      ContinuumOidcAttempt.update_all(expires_at: 1.second.ago)
      callback(state)
      assert_response :bad_request
      assert_empty ContinuumOidcAttempt.all

      state = begin_login
      get "/auth/callback", params: { state:, error: "access_denied" }
      assert_response :bad_request
      callback(state)
      assert_response :bad_request
      assert_empty ContinuumSession.all
    end

    test "grant failures hide links while identity remains until genuine invalidation" do
      write_registry(1, %w[muzeum continuum-engine continuum])
      sign_in
      context = ContinuumSession.sole.shell_context
      destinations(context)
      assert_equal %w[muzeum continuum-engine], response.parsed_body.fetch("destinations").pluck("id")
      assert_not_includes ContinuumSession.sole.encrypted_grant, "grant"

      provider = @providers.fetch("network.harvj.com")
      provider.eligible = %w[continuum-engine]
      write_registry(2, %w[continuum-engine continuum])
      destinations(context)
      assert_equal %w[continuum-engine], response.parsed_body.fetch("destinations").pluck("id")

      @root.join("registry.json").write("{broken")
      destinations(context)
      assert_equal %w[continuum-engine], response.parsed_body.fetch("destinations").pluck("id")
      write_registry(1, %w[muzeum continuum-engine continuum])
      provider.eligible = %w[muzeum continuum-engine]
      destinations(context)
      assert_equal %w[continuum-engine], response.parsed_body.fetch("destinations").pluck("id")

      provider.evidence_outage = true
      destinations(context)
      assert_response :no_content
      provider.outage = true
      get "/"
      assert_select ".shell-session-name", text: "jim"
      destinations(context)
      assert_response :no_content

      provider.outage = provider.evidence_outage = false
      provider.active = false
      destinations(context)
      assert_response :unauthorized
      assert_empty ContinuumSession.all
      get "/"
      assert_select ".shell-session", count: 0
    end

    test "session expiry, replacement context and CSRF-protected local logout" do
      sign_in
      old_context = ContinuumSession.sole.shell_context
      post "/logout"
      assert_response :unprocessable_content
      assert ContinuumSession.exists?

      ContinuumSession.update_all(expires_at: 1.second.ago)
      destinations(old_context)
      assert_response :unauthorized
      sign_in
      destinations(old_context)
      assert_response :unauthorized

      get "/"
      token = css_select("form[action='/logout'] input[name='authenticity_token']").sole["value"]
      @providers.fetch("network.harvj.com").outage = true
      post "/logout", params: { authenticity_token: token }, headers: { "Origin" => "https://network.harvj.com" }
      assert_response :see_other
      assert_empty ContinuumSession.all
      get "/"
      assert_select ".shell-session", count: 0
    end

    private

    def begin_login
      get "/login"
      assert_response :redirect
      assert_includes Array(response.headers["Set-Cookie"]).join("\n"), "secure"
      assert_includes response.location, "redirect_uri=#{CGI.escape("https://#{request.host}/auth/callback")}"
      URI.decode_www_form(URI(response.location).query).to_h.fetch("state")
    end

    def callback(state)
      get "/auth/callback", params: { code: "verified-test-code", state: }
    end

    def sign_in
      callback(begin_login)
      assert_response :see_other
      assert_includes Array(response.headers["Set-Cookie"]).join("\n"), "__Host-continuum-session="
    end

    def destinations(context)
      get "/shell/destinations", headers: { "X-Continuum-Shell" => context }
    end

    def write_registry(sequence, ids)
      hosts = { "continuum" => "library.harvj.com", "muzeum" => "muzeum.fm", "continuum-engine" => "funding.harvj.com" }
      entries = ids.map do |id|
        { id:, name: id, canonical_url: "https://#{hosts.fetch(id)}/", availability: "production" }
      end
      registry = { schema_version: 1, specification_version: "1.3.0", applications: entries }
      raw = registry.to_json
      @root.join("registry.json").write({ format_version: 1, sequence:, specification_version: "1.3.0",
        registry_sha256: Digest::SHA256.hexdigest(raw), registry_json: raw, registry: }.to_json)
    end
  end
end
