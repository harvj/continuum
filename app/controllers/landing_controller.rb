class LandingController < ActionController::Base
  include ContinuumSessionAccess
  SECTIONS = %w[network library intelligence].freeze
  ARTWORK = %w[background favicon favicon_png].freeze
  NETWORK_MODES = %w[light dark].freeze
  ARTWORK_IDS = (SECTIONS.product(ARTWORK).map { |section, kind| "continuum.#{section}_#{kind}" } +
    NETWORK_MODES.map { |mode| "continuum.network_background_#{mode}" }).freeze
  NEUTRAL_FAVICON = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"/>'.freeze
  NEUTRAL_FAVICON_PATH = "/favicon/neutral.svg"

  def show
    @section = section
    @managed_content = Rails.application.config.x.intelligence_content&.current if @section == "intelligence"
    @page_title = @managed_content&.title || @section.capitalize
    config = Rails.application.config.x
    @release_label = config.release_identity&.label || "v#{config.version}"
    @auth_session = resolve_session
    @auth_registration = session_registration(@auth_session) if @auth_session
    snapshot = artwork.snapshot
    @background = snapshot[artwork_id("background")]
    variants = network_variants(snapshot)
    @backgrounds = variants if variants.size == NETWORK_MODES.size
    @background ||= variants.values.first unless @backgrounds
    @favicons = favicons(snapshot)
    response.headers["Cache-Control"] = "no-store"
  end

  def background
    snapshot = artwork.snapshot
    candidates = [snapshot[artwork_id("background")], *network_variants(snapshot).values]
    asset = candidates.compact.find { |candidate| candidate.digest == params[:digest] }
    return head :not_found unless asset

    serve_image(asset.bytes, asset.media_type)
  end

  def favicon_discovery
    icons = favicons(artwork.snapshot)
    icon = icons.find { |candidate| candidate.media_type == "image/png" } || icons.first
    response.headers["Cache-Control"] = "no-store"
    redirect_to icon ? favicon_path(icon) : NEUTRAL_FAVICON_PATH
  end

  def favicon
    asset = favicons(artwork.snapshot).find do |icon|
      icon.digest == params[:digest] && icon.extension == ".#{params[:extension]}"
    end
    return head :not_found unless asset

    serve_image(asset.bytes, asset.media_type)
  end

  def neutral_favicon
    serve_image(NEUTRAL_FAVICON, "image/svg+xml")
  end

  helper_method :favicon_path

  def ready
    ActiveRecord::Base.connection_pool.with_connection { |connection| connection.select_value("SELECT 1") }
    head :ok
  rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::StatementInvalid
    head :service_unavailable
  end

  private

  def section
    request.host.split(".").first
  end

  def artwork_id(kind)
    "continuum.#{section}_#{kind}"
  end

  def network_variants(snapshot)
    return {} unless section == "network"

    NETWORK_MODES.index_with { |mode| snapshot[artwork_id("background_#{mode}")] }.compact
  end

  def favicons(snapshot)
    primary = snapshot[artwork_id("favicon")]
    png = snapshot[artwork_id("favicon_png")]
    return [primary] if primary&.media_type == "image/png"

    [png, primary].compact
  end

  def favicon_path(icon)
    "/favicon/#{icon.digest}#{icon.extension}"
  end

  def serve_image(bytes, media_type)
    response.headers["Content-Security-Policy"] = "default-src 'none'; sandbox"
    response.headers["X-Content-Type-Options"] = "nosniff"
    expires_in 1.year, public: true, immutable: true
    send_data bytes, type: media_type, disposition: "inline"
  end

  def artwork
    Rails.application.config.x.site_art
  end
end
