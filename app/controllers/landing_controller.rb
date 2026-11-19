class LandingController < ActionController::Base
  SECTIONS = {
    "network" => "continuum.network_background",
    "library" => "continuum.library_background",
    "intelligence" => "continuum.intelligence_background"
  }.freeze

  def show
    @section = section
    @background = artwork.resolve(SECTIONS.fetch(section))
    response.headers["Cache-Control"] = "no-store"
  end

  def background
    asset = artwork.resolve(SECTIONS.fetch(section))
    return head :not_found unless asset&.digest == params[:digest]

    response.headers["Content-Security-Policy"] = "default-src 'none'; sandbox"
    response.headers["X-Content-Type-Options"] = "nosniff"
    expires_in 1.year, public: true, immutable: true
    send_data asset.bytes, type: asset.media_type, disposition: "inline"
  end

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

  def artwork
    Rails.application.config.x.site_art
  end
end
