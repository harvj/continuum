Rails.application.routes.draw do
  get "up", to: "rails/health#show"
  get "ready", to: "landing#ready"

  LandingController::SECTIONS.each_key do |section|
    constraints host: "#{section}.harvj.com" do
      root "landing#show", as: "#{section}_home"
      get "background/:digest", to: "landing#background",
        constraints: { digest: /[0-9a-f]{64}/ }, format: false
    end
  end
end
