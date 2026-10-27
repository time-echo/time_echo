Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

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
      get "ping", to: proc { [ 200, { "Content-Type" => "application/json" }, [ { status: "ok", timestamp: Time.current.iso8601 }.to_json ] ] }

      resources :letters, only: [ :index, :show, :create, :destroy ] do
        post "predictions", to: "letter_predictions#update"
        scope module: :letters do
          resource :archive, only: [ :create ]
          resource :restore, only: [ :create ]
        end
      end
    end
  end

  if Rails.env.test?
    namespace :api, defaults: { format: :json } do
      namespace :v1 do
        get "dummy/public", to: "dummy#public_action"
        get "dummy/protected", to: "dummy#protected_action"
        get "dummy/error", to: "dummy#error_action"
        get "dummy/invalid", to: "dummy#invalid_action"
        post "dummy/bad_request", to: "dummy#bad_request_action"
      end
    end
  end

  mount GoodJob::Engine => "/good_job", constraints: ->(request) { request.session[:current_user_email].present? }
end
