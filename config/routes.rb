Rails.application.routes.draw do
  root to: 'pages#about'

  get '/logout',  to: 'user_sessions#destroy', as: :logout
  get '/login',   to: 'user_sessions#new',     as: :login
  get '/about',   to: 'pages#about',           as: :about
  get '/contact', to: 'pages#contact',         as: :contact
  get '/robots',  to: 'pages#robots',          as: :robots

  get '/activate/:id',              to: 'activations#create', as: :activation
  get '/register/:activation_code', to: 'activations#new',    as: :registration
  get 'tags/:tag',                  to: 'concepts#index',     as: :tag

  resource :account
  resources :password_resets, only: [:new, :create, :edit, :update]
  resources :settings, only: [:index, :show, :edit, :update]
  resources :users do
    member do
      get   :summary
      patch :approve
    end
    collection do
      get   :names
    end
  end
  resources :user_sessions, only: [:create, :destroy]
  resources :votes
end
