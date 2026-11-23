require_relative "boot"
require_relative "../lib/continuum_release_identity"
require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "active_storage/engine"
require "rails/test_unit/railtie"

module Continuum
  class Application < Rails::Application
    config.load_defaults 8.1
    release_root = File.realpath(File.expand_path("..", __dir__))
    config.x.version = ContinuumVersion.read(release_root).freeze
    if ENV["CONTINUUM_RELEASE_STORE"] || ENV["CONTINUUM_RELEASE_TRUST_KEY"] ||
      File.exist?(File.join(release_root, ContinuumReleaseIdentity::BINDING))
      config.x.release_identity = ContinuumReleaseIdentity::Running.new(root: release_root,
        store: ENV.fetch("CONTINUUM_RELEASE_STORE"), trust_key: ENV.fetch("CONTINUUM_RELEASE_TRUST_KEY"),
        packaged_version: config.x.version, logger: Rails.logger)
    end
    config.hosts = %w[network.harvj.com library.harvj.com intelligence.harvj.com]
    config.active_storage.service = :local
    config.active_storage.draw_routes = false
    config.public_file_server.enabled = true
    config.filter_parameters += %i[code state nonce verifier grant token client_secret]
    config.session_store :cookie_store, key: "__Host-continuum-csrf", secure: true, httponly: true, same_site: :lax, path: "/"
    config.x.site_art_root = ENV.fetch("SITE_ART_ROOT", "/var/www/site-art/public")
    config.content_security_policy do |policy|
      policy.default_src :none
      policy.style_src :self
      policy.script_src :self
      policy.font_src :self
      policy.img_src :self
      policy.connect_src :self
      policy.form_action :self
      policy.base_uri :none
      policy.frame_ancestors :none
    end
  end
end
