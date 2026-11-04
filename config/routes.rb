Rails.application.routes.draw do
  # Authentication
  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[new create]

  # Signed-in user
  resource :account, only: %i[show update destroy]
  root "today#show"

  # Health check for Railway (returns 200 when the app boots)
  get "up" => "rails/health#show", as: :rails_health_check

  # Installable web app on Android ("Add to Home screen")
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
