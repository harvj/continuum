Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = false
  config.active_record.maintain_test_schema = false
  config.consider_all_requests_local = true
  config.action_dispatch.show_exceptions = :rescuable
end
