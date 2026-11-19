ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
require "rails/test_help"
require "tmpdir"

class LandingTest < ActionDispatch::IntegrationTest
  self.use_transactional_tests = false
  def setup
    @root = Pathname(Dir.mktmpdir)
    @root.join("assets").mkdir
    @time = 0
    @original = Rails.application.config.x.site_art
    Rails.application.config.x.site_art = SiteArt.new(@root,
      identifiers: LandingController::SECTIONS.values, clock: -> { @time })
    host! "network.harvj.com"
  end

  def teardown
    Rails.application.config.x.site_art = @original
    FileUtils.remove_entry(@root)
  end

  test "all hosts share accessible navigation with empty main and footer" do
    LandingController::SECTIONS.each_key do |section|
      host! "#{section}.harvj.com"
      get "/"
      assert_response :success
      assert_select "header .wordmark[href='https://harvj.com']", text: "harvj."
      assert_select "nav a" do |links|
        assert_equal %w[Network Library Intelligence Home], links.map { |link| link["aria-label"] || link.text }
        assert_equal "https://auth.harvj.com", links.last["href"]
      end
      assert_select "nav a[aria-current=page]", count: 1, text: section.capitalize
      assert_select "main", text: ""
      assert_select "main *", count: 0
      assert_select "footer", text: "© 2026 Jim Harvey · Continuum v#{ContinuumVersion.read}"
    end
    get "/up"
    assert_response :success
    host! "elsewhere.example"
    get "/"
    assert_response :forbidden
  end

  test "publication update failure rollback and removal" do
    get "/"
    assert_select "img.background", count: 0

    first = publish("ivory")
    get "/"
    assert_select "img.background", count: 0
    assert_background first
    good_manifest = @root.join("manifest.json").binread

    second = publish("navy")
    assert_background second
    latest = @root.join("manifest.json").binread
    publish("red", valid: false)
    assert_background second
    @root.join("manifest.json").delete
    assert_background second
    @root.join("manifest.json").binwrite(latest.sub('"rights":"Synthetic fixture"', '"rights":"Changed without updating release"'))
    assert_background second

    @root.join("manifest.json").binwrite(good_manifest)
    assert_background first
    assert_manifest({})
    @time += 30
    get "/"
    assert_select "img.background", count: 0
    get "/background/#{first}"
    assert_response :not_found
  end

  test "readiness checks Postgres when a test database is configured" do
    skip "Set CONTINUUM_TEST_POSTGRES=1 to test database readiness" unless ENV["CONTINUUM_TEST_POSTGRES"] == "1"

    get "/ready"
    assert_response :success
  end

  private

  def assert_background(digest)
    @time += 30
    get "/"
    assert_response :success
    url = "/background/#{digest}"
    assert_select "img.background[src='#{url}'][alt='']", count: 1
    get url
    assert_response :success
    assert_equal "image/svg+xml", response.media_type
    assert_equal digest, Digest::SHA256.hexdigest(response.body)
  end

  def publish(color, valid: true)
    bytes = %(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"><rect width="1" height="1" fill="#{color}"/></svg>)
    digest = Digest::SHA256.hexdigest(bytes)
    @root.join("assets", "#{digest}.svg").binwrite(bytes) if valid
    assert_manifest("continuum.network_background" => {
      "bytes" => bytes.bytesize, "media_type" => "image/svg+xml", "rights" => "Synthetic fixture",
      "sha256" => digest, "url" => "https://art.harvj.com/assets/#{digest}.svg"
    })
    digest
  end

  def assert_manifest(assets)
    payload = { "assets" => assets, "commit" => "a" * 40, "schema_version" => 1 }
    release = Digest::SHA256.hexdigest(JSON.generate(payload) + "\n")
    @root.join("manifest.json").binwrite(JSON.generate(payload.merge("release" => release)))
  end
end
