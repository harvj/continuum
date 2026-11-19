ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
require "rails/test_help"
require "tmpdir"
require "base64"

class LandingTest < ActionDispatch::IntegrationTest
  self.use_transactional_tests = false
  def setup
    @root = Pathname(Dir.mktmpdir)
    @root.join("assets").mkdir
    @time = 0
    @original = Rails.application.config.x.site_art
    Rails.application.config.x.site_art = SiteArt.new(@root,
      identifiers: LandingController::ARTWORK_IDS, clock: -> { @time })
    host! "network.harvj.com"
  end

  def teardown
    Rails.application.config.x.site_art = @original
    FileUtils.remove_entry(@root)
  end

  test "all hosts share accessible navigation with empty main and footer" do
    LandingController::SECTIONS.each do |section|
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
      assert_select 'link[rel=icon][type="image/svg+xml"][sizes=any][href="/favicon/neutral.svg"]', count: 1
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

  test "foreground updates independently of image bytes and rolls back with the snapshot" do
    host! "intelligence.harvj.com"
    id = "continuum.intelligence_background"
    image = svg_record("ivory")
    digest = image.fetch("sha256")
    dark = image.merge("foreground" => "dark")
    assert_manifest(id => dark)
    get "/"
    assert_select "body[data-foreground=dark] img.background[src='/background/#{digest}']"
    saved = @root.join("manifest.json").binread

    assert_manifest(id => image.merge("foreground" => "light"))
    @time = 29
    get "/"
    assert_select "body[data-foreground=dark]"
    @time = 30
    get "/"
    assert_select "body[data-foreground=light] img.background[src='/background/#{digest}']"

    [image.merge("foreground" => "auto"), image.merge("foreground" => nil)].each do |invalid|
      assert_manifest(id => invalid)
      @time += 30
      get "/"
      assert_select "body[data-foreground=light]"
    end

    assert_manifest(id => image)
    @time += 30
    get "/"
    assert_select "body:not([data-foreground]) img.background[src='/background/#{digest}']"

    @root.join("manifest.json").binwrite(saved)
    @time += 30
    get "/"
    assert_select "body[data-foreground=dark] img.background[src='/background/#{digest}']"
  end

  test "all hosts pick only their own verified background and icons" do
    records = {}
    sections = LandingController::SECTIONS
    sections.zip(%w[ivory navy ivory], %w[dark light dark]).each do |section, color, foreground|
      records["continuum.#{section}_background"] = svg_record(color, width: 4).merge("foreground" => foreground)
      records["continuum.#{section}_favicon"] = svg_record(color)
    end
    png = png_record
    records["continuum.network_favicon_png"] = png
    records["continuum.library_favicon"] = png
    assert_manifest(records)

    sections.each do |section|
      host! "#{section}.harvj.com"
      get "/"
      assert_response :success
      background = records.fetch("continuum.#{section}_background")
      assert_select "body[data-foreground=#{background.fetch("foreground")}] img.background[src='/background/#{background.fetch("sha256")}']", count: 1
      primary = records.fetch("continuum.#{section}_favicon")
      expected = section == "network" ? [png, primary] : [primary]
      assert_select "link[rel=icon]" do |links|
        assert_equal expected.map { |record| icon_url(record) }, links.map { |link| link["href"] }
        assert_equal expected.map { |record| record["media_type"] }, links.map { |link| link["type"] }
      end
      get "/favicon.ico"
      assert_redirected_to icon_url(expected.first)
      assert_equal "no-store", response.headers["Cache-Control"]
      get icon_url(primary)
      assert_response :success
      assert_equal primary.fetch("media_type"), response.media_type
      assert_equal primary.fetch("sha256"), Digest::SHA256.hexdigest(response.body)
      assert_includes response.headers["Cache-Control"], "immutable"
      assert_equal "nosniff", response.headers["X-Content-Type-Options"]
      assert_includes response.headers["Content-Security-Policy"], "sandbox"
    end
    get icon_url(png)
    assert_response :not_found
  end

  test "fallback first publication update bad snapshot and rollback are refreshed together" do
    get "/favicon.ico"
    assert_redirected_to "/favicon/neutral.svg"
    assert_equal "no-store", response.headers["Cache-Control"]
    get "/favicon/neutral.svg"
    assert_response :success
    assert_equal "image/svg+xml", response.media_type

    id = "continuum.network_favicon"
    first = svg_record("orange")
    second = svg_record("purple")
    background = svg_record("pink", width: 8)
    assert_manifest(id => first, "continuum.network_background" => background)
    saved = @root.join("manifest.json").binread

    @time = 29
    assert_icon "/favicon/neutral.svg"
    @time = 30
    assert_icon icon_url(first)
    get "/"
    assert_select "img.background", count: 1

    assert_manifest(id => second)
    @time += 30
    assert_icon icon_url(second)
    get icon_url(first)
    assert_response :not_found
    get icon_url(second).sub(/svg\z/, "png")
    assert_response :not_found

    wrong_url = first.merge("url" => first["url"].sub("art.harvj.com", "invalid.example"))
    wrong_type = first.merge("media_type" => "image/png")
    [wrong_url, wrong_type, first.except("rights"), first.merge("bytes" => first["bytes"] + 1)].each do |record|
      assert_manifest(id => record)
      @time += 30
      assert_icon icon_url(second)
    end
    assert_manifest(id => first)
    @root.join("manifest.json").binwrite(@root.join("manifest.json").binread.sub('"schema_version":1', '"schema_version":2,"schema_version":1'))
    @time += 30
    assert_icon icon_url(second)

    @root.join("manifest.json").delete
    @time += 30
    assert_icon icon_url(second)
    @root.join("manifest.json").binwrite(saved)
    @time += 30
    assert_icon icon_url(first)
    get "/"
    assert_select "img.background", count: 1

    fallback = png_record
    assert_manifest("continuum.network_favicon_png" => fallback)
    @time += 30
    assert_icon icon_url(fallback)

    assert_manifest({})
    @time += 30
    assert_icon "/favicon/neutral.svg"
    get "/up"
    assert_response :success
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

  def assert_icon(path)
    get "/"
    assert_response :success
    assert_select "link[rel=icon][href='#{path}']", count: 1
  end

  def icon_url(record)
    "/favicon/#{File.basename(record.fetch("url"))}"
  end

  def publish(color, valid: true)
    record = svg_record(color, valid: valid)
    assert_manifest("continuum.network_background" => record)
    record.fetch("sha256")
  end

  def svg_record(color, width: 1, valid: true)
    bytes = %(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{width} 1"><rect width="#{width}" height="1" fill="#{color}"/></svg>)
    asset_record(bytes, "svg", "image/svg+xml", valid: valid)
  end

  def png_record
    bytes = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jxZkAAAAASUVORK5CYII=")
    asset_record(bytes, "png", "image/png")
  end

  def asset_record(bytes, extension, media_type, valid: true)
    digest = Digest::SHA256.hexdigest(bytes)
    filename = "#{digest}.#{extension}"
    @root.join("assets", filename).binwrite(bytes) if valid
    { "bytes" => bytes.bytesize, "media_type" => media_type, "rights" => "Synthetic fixture",
      "sha256" => digest, "url" => "https://art.harvj.com/assets/#{filename}" }
  end

  def assert_manifest(assets)
    payload = { "assets" => assets.sort.to_h.transform_values { |record| record.sort.to_h }, "commit" => "a" * 40, "schema_version" => 1 }
    release = Digest::SHA256.hexdigest(JSON.generate(payload) + "\n")
    @root.join("manifest.json").binwrite(JSON.generate(payload.merge("release" => release)))
  end
end
