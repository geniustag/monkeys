Rails.application.routes.draw do
  root 'home#index'
  get "home" => "home#index"

  get "logout" => "session#logout"
  get "login" => "session#login"
  post "login" => "session#login"

  post "buy" => "home#buy"
  get "grab_key" => "home#grab_key"
  get "check_key" => "home#check_key"

  namespace :admin do
    %w(users).each do |a|
      get a = "#{a}_sta" => "statistics##{a}"
    end
    resources :users
    resources :games
  end
end
