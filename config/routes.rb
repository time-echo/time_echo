Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "livez", to: "api/v1/health#liveness", defaults: { format: :json }
  get "readyz", to: "api/v1/health#show", defaults: { format: :json }

  root "pages#landing"

  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  get "login/:token", to: "sessions#show", as: :magic_login
  delete "logout", to: "sessions#destroy", as: :logout

  get "check_email", to: "check_emails#show", as: :check_email

  get "letters/success", to: "letter_successes#show", as: :success_letters

  post "letters/:letter_id/predictions", to: "letter_predictions#update", as: :update_predictions_letter
  namespace :letters do
    resource :archive, only: [ :create ], path: ":letter_id/archive"
    resource :restore, only: [ :create ], path: ":letter_id/restore"
  end
  resources :letters, only: [ :new, :create, :show, :destroy ]

  resources :locales, only: [ :create, :destroy ]

  get "dashboard", to: "letters#index", as: :dashboard

  get "analytics", to: "analytics#index", as: :analytics

  get "settings", to: "settings#show", as: :settings
  patch "settings", to: "settings#update"
  delete "settings", to: "settings#destroy"

  get "settings/confirm_email", to: "settings/email_confirmations#show", as: :confirm_email_update_settings

  get "privacy", to: "pages#privacy", as: :privacy
  get "terms", to: "pages#terms", as: :terms
  get "about", to: "pages#about", as: :about

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      get "ping", to: proc {
        payload = {
          data: { status: "ok", timestamp: Time.current.iso8601 },
          meta: {}
        }.to_json
        [ 200, { "Content-Type" => "application/json" }, [ payload ] ]
      }

      get "health", to: "health#show"
      get "health/liveness", to: "health#liveness"

      resources :letters, only: [ :index, :show, :create, :destroy ] do
        post "predictions", to: "letter_predictions#update"
        scope module: :letters do
          resource :archive, only: [ :create ]
          resource :restore, only: [ :create ]
        end
      end

      resource :session, only: [ :destroy ] do
        get :me
      end
      resources :sessions, only: [ :create, :show ], param: :token do
        collection do
          get :me
        end
      end
      delete "sessions", to: "sessions#destroy"

      resource :account, only: [ :update, :destroy ] do
        scope module: :accounts do
          resource :email_confirmation, only: [ :show, :create ], path: "confirm_email"
        end
      end
    end
  end

  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  mount GoodJob::Engine => "/good_job", constraints: ->(request) { request.session[:current_user_email].present? }

  # Catch-all route to return 404 JSON error contract for unmatched routes
  match "*path", to: "api/v1/base#route_not_found", via: :all, defaults: { format: :json }
end
