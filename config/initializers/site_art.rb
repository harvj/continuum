Rails.application.config.to_prepare do
  config = Rails.application.config
  config.x.site_art = SiteArt.new(config.x.site_art_root, identifiers: LandingController::SECTIONS.values)
end
