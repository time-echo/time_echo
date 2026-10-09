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

  mount GoodJob::Engine => "/good_job", constraints: ->(request) { request.session[:current_user_email].present? }
end
