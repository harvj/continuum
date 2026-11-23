Rails.application.config.to_prepare do
  config = Rails.application.config.x
  config.auth_registrations = ContinuumAuth.registrations(ENV.fetch("CONTINUUM_AUTH_REGISTRATIONS", "{}"))
  config.auth_provider = ->(registration) { ContinuumAuth.new(registration) }
  config.shell_registry = ShellRegistry.new(ENV["CONTINUUM_SHELL_REGISTRY"])
end
