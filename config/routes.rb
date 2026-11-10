Rails.application.routes.draw do
  # Authentication
  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[new create]

  # Signed-in user
  resource :account, only: %i[show update destroy]
  root "today#show"
  resource :dashboard, only: :show
  resource :phone, only: :show, controller: "phone"
  resource :plan, only: :show, controller: "plan"
  resource :plan_template, only: %i[show create], controller: "plan_templates"

  resources :subjects, except: %i[show new edit] do
    resources :topics, only: :create
  end
  resources :topics, only: %i[update destroy]
  resources :tasks, except: %i[show new edit] do
    collection do
      patch :reorder
      delete :destroy_all
    end
    member do
      patch :toggle
      patch :restore
    end
    resources :subtasks, only: :create, controller: "task_subtasks"
    patch "subtasks/:subtask_id/toggle", to: "task_subtasks#toggle", as: :toggle_task_subtask
    delete "subtasks/:subtask_id", to: "task_subtasks#destroy", as: :task_subtask
  end
  namespace :settings do
    resources :devices, only: %i[index destroy]
  end

  # JSON API for the Android collector (docs/api.md)
  namespace :api do
    namespace :v1 do
      resources :tokens, only: :create
      delete "tokens/current", to: "tokens#destroy"
      post "devices/heartbeat", to: "devices#heartbeat"
      resources :app_usage_days, :app_sessions, :screen_events, :health_samples, :sleep_sessions, :check_ins, only: :create
    end
  end

  # Health check for Railway (returns 200 when the app boots)
  get "up" => "rails/health#show", as: :rails_health_check

  # Installable web app on Android ("Add to Home screen")
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
