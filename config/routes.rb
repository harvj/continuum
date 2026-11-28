Rails.application.routes.draw do
  get "up", to: "rails/health#show"
  get "ready", to: "landing#ready"

  LandingController::SECTIONS.each do |section|
    constraints host: "#{section}.harvj.com" do
      root "landing#show", as: "#{section}_home"
      get "login", to: "auth_sessions#login"
      get "auth/callback", to: "auth_sessions#callback"
      post "auth/session/prepare", to: "auth_sessions#prepare"
      get "auth/start", to: "auth_sessions#start"
      post "auth/session", to: "auth_sessions#bootstrap"
      get "shell/destinations", to: "auth_sessions#destinations"
      post "logout", to: "auth_sessions#destroy"
      get "favicon.ico", to: "landing#favicon_discovery", format: false
      get "favicon/neutral.svg", to: "landing#neutral_favicon", format: false
      get "favicon/:digest.:extension", to: "landing#favicon",
        constraints: { digest: /[0-9a-f]{64}/, extension: /svg|png/ }, format: false
      get "background/:digest", to: "landing#background",
        constraints: { digest: /[0-9a-f]{64}/ }, format: false
    end
  end
end
