require_relative "boot"
require_relative "../lib/continuum_version"
require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "active_storage/engine"
require "rails/test_unit/railtie"

module Continuum
  class Application < Rails::Application
    config.load_defaults 8.1
    config.x.version = ContinuumVersion.read.freeze
    config.hosts = %w[network.harvj.com library.harvj.com intelligence.harvj.com]
    config.active_storage.service = :local
    config.active_storage.draw_routes = false
    config.public_file_server.enabled = true
    config.x.site_art_root = ENV.fetch("SITE_ART_ROOT", "/var/www/site-art/public")
    config.content_security_policy do |policy|
      policy.default_src :none
      policy.style_src :self
      policy.script_src :self
      policy.font_src :self
      policy.img_src :self
      policy.base_uri :none
      policy.frame_ancestors :none
    end
  end
end
