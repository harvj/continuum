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
      assert_select "footer", text: "© #{Time.current.year} Jim Harvey · Continuum v#{ContinuumVersion.read}"
    end
    get "/up"
    assert_response :success
    host! "elsewhere.example"
    get "/"
    assert_response :forbidden
  end

  test "the footer rolls over the calendar year while keeping the running version" do
    version = Rails.application.config.x.version
    travel_to Time.utc(2027, 1, 1, 12) do
      LandingController::SECTIONS.each do |section|
        host! "#{section}.harvj.com"
        get "/"
        assert_response :success
        assert_select "footer", text: "© 2027 Jim Harvey · Continuum v#{version}"
        assert_select "footer a[href='https://harvj.com']", text: "Jim Harvey"
      end
    end
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
    assert_select "img.background[data-art-legacy=dark][src='/background/#{digest}']"
    saved = @root.join("manifest.json").binread

    assert_manifest(id => image.merge("foreground" => "light"))
    @time = 29
    get "/"
    assert_select "img.background[data-art-legacy=dark]"
    @time = 30
    get "/"
    assert_select "img.background[data-art-legacy=light][src='/background/#{digest}']"

    [image.merge("foreground" => "auto"), image.merge("foreground" => nil)].each do |invalid|
      assert_manifest(id => invalid)
      @time += 30
      get "/"
      assert_select "img.background:not([data-art-legacy])"
    end

    assert_manifest(id => image)
    @time += 30
    get "/"
    assert_select "img.background:not([data-art-legacy])[src='/background/#{digest}']"

    @root.join("manifest.json").binwrite(saved)
    @time += 30
    get "/"
    assert_select "img.background[data-art-legacy=dark][src='/background/#{digest}']"
  end

  test "presentation fixtures resolve by role and stay paired with verified image bytes" do
    fixtures = JSON.parse(File.read(File.join(__dir__, "fixtures/site_art_presentation.json")))
    id = "continuum.network_background"
    image = svg_record("ivory")
    digest = image.fetch("sha256")
    alternate = svg_record("navy")
    first_manifest = nil
    first_bytes = nil
    fixtures.fetch("assets").each do |name, fixture|
      fields = fixture.fetch("fields")
      record = case name
      when "other_theme" then alternate
      when "invalid_core" then image.merge("url" => image.fetch("url") + "?bad")
      else image.merge(fields)
      end
      assert_manifest(id => record, "future.asset" => { "nested" => [{ "z" => 0, "a" => 1 }] })
      first_manifest ||= @root.join("manifest.json").binread
      @time += 30
      get "/"
      if fixture["expected"].nil?
        assert_select "img.background", count: 0
        next
      end

      if %w[flat regional zero unknown invalid_optional legacy plain].include?(name)
        bytes = Rails.application.config.x.site_art.snapshot.fetch(id).bytes
        first_bytes ||= bytes
        assert_same first_bytes, bytes
      end

      assert_select "header[data-art-role=top]"
      assert_select "main[data-art-role=default]"
      assert_select "footer[data-art-role=bottom]"
      assert_select "script[src='/site-art.js'][defer]"
      assert_includes response.headers.fetch("Content-Security-Policy"), "script-src 'self'"
      assert_select "img.background[src='/background/#{record.fetch("sha256")}']", count: 1 do |images|
        node = images.first
        treatment = JSON.parse(node["data-art-presentation"])
        fixture.fetch("expected").each do |role, expected|
          values = fixtures.fetch("expected_treatments").fetch(expected).dup
          if !fields["foreground"].nil? && values["--art-foreground"] == fixtures.fetch("legacy_palette")[fields["foreground"]]
            values.delete("--art-foreground")
            assert_equal fields["foreground"], node["data-art-legacy"]
          end
          assert_equal values, treatment.fetch(role), "#{name} / #{role}"
        end
      end
    end

    @root.join("manifest.json").binwrite(first_manifest)
    @time += 30
    get "/"
    assert_select "img.background[src='/background/#{digest}'][data-art-legacy=dark]" do |images|
      assert_equal "#F5EFE3", JSON.parse(images.first["data-art-presentation"]).dig("top", "--art-foreground")
    end
  end

  test "canonical publisher JSON accepts integral optional floats and ignores fractional values" do
    image = svg_record("ivory")
    canonical = (<<~JSON).lines.map(&:strip).join
      {"assets":{"continuum.network_background":{
        "bytes":#{image.fetch("bytes")},"media_type":"image/svg+xml",
        "presentation":{
          "regions":{"top":{"text_shadow":{
            "blur_px":1e-05,"color":"#112233","opacity_percent":20,"x_px":0,"y_px":1
          }}},
          "text_shadow":{"blur_px":2.0,"color":"#010203","opacity_percent":40.0,"x_px":-4.0,"y_px":0.0}
        },
        "rights":"\\u007f\\u05d0","sha256":"#{image.fetch("sha256")}","url":"#{image.fetch("url")}"
      }},"commit":"#{"a" * 40}","schema_version":1}
    JSON
    release = Digest::SHA256.hexdigest(canonical + "\n")
    @root.join("manifest.json").binwrite(canonical.delete_suffix("}") + %Q(,"release":"#{release}"}))
    get "/"
    assert_select "img.background" do |images|
      values = JSON.parse(images.first["data-art-presentation"])
      assert_equal "-4px 0px 2px rgb(1 2 3 / 40%)", values.dig("top", "--art-text-shadow")
    end
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
      assert_select "img.background[data-art-legacy=#{background.fetch("foreground")}][src='/background/#{background.fetch("sha256")}']", count: 1
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
    assert_manifest(id => first.merge("bytes" => first["bytes"] + 1))
    @time += 30
    assert_icon icon_url(second)

    [wrong_url, wrong_type, first.except("rights")].each do |record|
      assert_manifest(id => record)
      @time += 30
      assert_icon "/favicon/neutral.svg"
    end
    assert_manifest(id => first)
    @root.join("manifest.json").binwrite(@root.join("manifest.json").binread.sub('"schema_version":1', '"schema_version":2,"schema_version":1'))
    @time += 30
    assert_icon "/favicon/neutral.svg"

    @root.join("manifest.json").delete
    @time += 30
    assert_icon "/favicon/neutral.svg"
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
    payload = { "assets" => assets, "commit" => "a" * 40, "schema_version" => 1 }
    canonical = ->(value) do
      case value
      when Hash then value.sort.to_h.transform_values(&canonical)
      when Array then value.map(&canonical)
      else value
      end
    end
    release = Digest::SHA256.hexdigest(JSON.generate(canonical.call(payload), ascii_only: true) + "\n")
    @root.join("manifest.json").binwrite(JSON.generate(payload.merge("release" => release)))
  end
end
