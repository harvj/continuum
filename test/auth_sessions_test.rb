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

    test "all public hosts remain anonymous until deliberate unified sign-in" do
      @providers.each_key do |host|
        reset!
        https!
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
      assert_response :ok
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

    test "one origin exchange establishes distinct host-only handles and one logout revokes the originating grant" do
      write_registry(1, %w[muzeum continuum-engine continuum])
      sign_in
      record = ContinuumSession.sole
      assert record.active?
      assert_equal 2, record.continuum_session_handles.count
      assert_equal 3, ([record.token_digest] + record.continuum_session_handles.pluck(:token_digest)).uniq.length
      @providers.each_key do |host|
        host! host
        get "/"
        assert_response :ok
        assert_select ".shell-session-name", text: "jim"
        destinations(record.shell_context)
        assert_equal %w[muzeum continuum-engine], response.parsed_body.fetch("destinations").pluck("id")
      end
      assert_equal [1, 0, 0], %w[network library intelligence].map { |section| @providers.fetch("#{section}.harvj.com").calls }

      get "/"
      token = css_select("form[action='/logout'] input[name='authenticity_token']").sole["value"]
      post "/logout", params: { authenticity_token: token }, headers: { "Origin" => "https://auth.harvj.com" }
      assert_response :unprocessable_content
      assert ContinuumSession.exists?(record.id)
      post "/logout", params: { authenticity_token: token }, headers: { "Origin" => "https://#{request.host}" }
      assert_response :see_other
      assert_equal "grant", @providers.fetch("network.harvj.com").revoked
      assert_nil @providers.fetch("intelligence.harvj.com").revoked
      assert_empty ContinuumSessionHandle.all
      destinations(record.shell_context)
      assert_response :unauthorized
      @providers.each_key do |host|
        host! host
        get "/"
        assert_select ".shell-session", count: 0
      end
    end

    test "bootstrap rejects unrelated origins, wrong host, replay and stale tickets" do
      callback(begin_login)
      target, ticket = bootstrap_form
      other = (@providers.keys - [request.host, target]).sole
      host! other
      post "/auth/session", params: { ticket: }, headers: { "Origin" => "https://network.harvj.com" }
      assert_response :bad_request

      thief = open_session
      thief.https!
      thief.host! target
      thief.post "/auth/session", params: { ticket: }, headers: { "Origin" => "https://network.harvj.com" }
      assert_equal 400, thief.response.status

      host! target
      post "/auth/session", params: { ticket: }, headers: { "Origin" => "https://auth.harvj.com" }
      assert_response :bad_request
      post "/auth/session", params: { ticket: "f" * 64 }, headers: { "Origin" => "https://network.harvj.com" }
      assert_response :bad_request
      post "/auth/session", params: { ticket: }, headers: { "Origin" => "https://network.harvj.com" }
      assert_response :ok
      next_target, next_ticket = bootstrap_form
      post "/auth/session", params: { ticket: }, headers: { "Origin" => "https://network.harvj.com" }
      assert_response :bad_request
      ContinuumSessionHandle.where(host: next_target).update_all(ticket_expires_at: 1.second.ago)
      host! next_target
      post "/auth/session", params: { ticket: next_ticket }, headers: { "Origin" => "https://#{target}" }
      assert_response :bad_request
      refute ContinuumSession.sole.active?
    end

    private

    def begin_login
      get "/login"
      assert_response :ok
      assert_includes Array(response.headers["Set-Cookie"]).join("\n"), "secure"
      2.times do
        source = request.host
        target, ticket = bootstrap_form
        host! target
        post "/auth/session/prepare", params: { ticket: }, headers: { "Origin" => "https://#{source}" }
        receiver = Array(response.headers["Set-Cookie"]).join("\n")
        assert_includes receiver, "__Host-continuum-receiver="
        refute_match(/domain=/i, receiver)
      end
      assert_response :ok
      get css_select("a").sole["href"]
      assert_response :redirect
      assert_includes response.location, "redirect_uri=#{CGI.escape("https://#{request.host}/auth/callback")}"
      URI.decode_www_form(URI(response.location).query).to_h.fetch("state")
    end

    def callback(state)
      get "/auth/callback", params: { code: "verified-test-code", state: }
    end

    def sign_in
      state = begin_login
      origin = request.host
      callback(state)
      assert_response :ok
      refute ContinuumSession.order(:id).last.active?
      2.times { follow_session_bootstrap }
      assert_response :ok
      assert_equal "https://#{origin}/", css_select("a").sole["href"]
      host! origin
    end

    def bootstrap_form
      action = URI(css_select("form").sole["action"])
      ticket = css_select('input[name="ticket"]').sole["value"]
      [action.host, ticket]
    end

    def follow_session_bootstrap
      source = request.host
      target, ticket = bootstrap_form
      assert_includes response.headers["Content-Security-Policy"], "form-action https://#{target}"
      assert_equal "no-store", response.headers["Cache-Control"].split(",").first
      host! target
      post "/auth/session", params: { ticket: }, headers: { "Origin" => "https://#{source}" }
      cookies_written = Array(response.headers["Set-Cookie"]).join("\n")
      assert_includes cookies_written, "__Host-continuum-session="
      assert_includes cookies_written, "secure"
      refute_match(/domain=/i, cookies_written)
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
