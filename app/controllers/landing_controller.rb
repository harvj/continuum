class LandingController < ActionController::Base
  SECTIONS = %w[network library intelligence].freeze
  ARTWORK = %w[background favicon favicon_png].freeze
  ARTWORK_IDS = SECTIONS.product(ARTWORK).map { |section, kind| "continuum.#{section}_#{kind}" }.freeze
  NEUTRAL_FAVICON = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"/>'.freeze
  NEUTRAL_FAVICON_PATH = "/favicon/neutral.svg"

  def show
    @section = section
    snapshot = artwork.snapshot
    @background = snapshot[artwork_id("background")]
    @favicons = favicons(snapshot)
    response.headers["Cache-Control"] = "no-store"
  end

  def background
    asset = artwork.snapshot[artwork_id("background")]
    return head :not_found unless asset&.digest == params[:digest]

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
