Rails.application.routes.draw do
  root 'home#index'
  get "home" => "home#index"

  get "logout" => "session#logout"
  get "login" => "session#login"
  post "login" => "session#login"

  post "buy" => "home#buy"

  namespace :admin do
    %w(users).each do |a|
      get a = "#{a}_sta" => "statistics##{a}"
    end
    resources :users
    resources :games
  end
end
