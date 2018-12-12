Rails.application.routes.draw do
  root 'home#index'
  get "home" => "home#index"

  get "logout" => "session#logout"
  get "login" => "session#login"
  post "login" => "session#login"

  get "downloads/app" => "app_versions#download"
  %w(privacy about app_downloads).each do |a|
    get a => "home##{a}"
  end

  namespace :admin do
    %w(members user_logs withdraws deposits).each do |a|
      get a = "#{a}_sta" => "statistics##{a}"
    end

    resources :statistics
    resources :app_versions do
      member do
        get :download
      end
    end
    resources :trade_bots do
      member do
        get "trade_pair"
        post "trade_pair"
        post "cancel_orders"
        get "orders"
      end
    end
    resources :servers
    resources :feedbacks
    resources :services
    resources :members
    resources :currencies
    resources :settings
    resources :account_versions
    resources :accounts do
      member do
        get :check
      end
    end
    resources :api_tokens
    resources :assets
    resources :audit_logs
    resources :authentications
    resources :comments
    resources :currencies
    resources :deposits
    resources :document_translations
    resources :documents
    resources :fund_sources
    resources :id_documents
    resources :identities
    resources :markets do
      collection do
        get :depth
      end
    end
    resources :members
    resources :oauth_access_grants
    resources :oauth_access_tokens
    resources :oauth_applications
    resources :orders
    resources :partial_trees
    resources :payment_transactions
    resources :proofs
    resources :read_marks
    resources :running_accounts
    resources :schema_migrations
    resources :signup_histories
    resources :simple_captcha_data
    resources :taggings
    resources :tags
    resources :tickets
    resources :tokens
    resources :trades
    resources :two_factors
    resources :user_logs
    resources :versions
    resources :withdraws do
      member do
        post :operate
      end
    end
  end

  require 'sidekiq/web'
  mount Sidekiq::Web => '/bv7cos3r7y93hn2iosnvvbdx3i4e5q6d123'
end
