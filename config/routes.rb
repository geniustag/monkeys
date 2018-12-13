Rails.application.routes.draw do
  root 'home#index'
  get "home" => "home#index"

  get "logout" => "session#logout"
  get "login" => "session#login"
  post "login" => "session#login"
  namespace :admin do
    %w(users).each do |a|
      get a = "#{a}_sta" => "statistics##{a}"
    end
    resources :users
    resources :games
  end
  require 'sidekiq/web'
  mount Sidekiq::Web => '/aaaa'
end
