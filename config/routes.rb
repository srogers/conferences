Rails.application.routes.draw do
  root to: 'pages#news'

  get '/logout',  to: 'user_sessions#destroy', as: :logout
  get '/login',   to: 'user_sessions#new',     as: :login
  get '/about',   to: 'pages#about',           as: :about
  get '/news',    to: 'pages#news',            as: :news
  get '/supporters',   to: 'pages#supporters', as: :supporters
  get '/guidelines',   to: 'pages#guidelines', as: :guidelines
  get '/tips',    to: 'pages#tips',            as: :tips
  get '/contact', to: 'pages#contact',         as: :contact
  get '/robots',  to: 'pages#robots',          as: :robots
  get '/privacy_policy', to: 'pages#privacy_policy', as: :privacy_policy
  get '/terms_of_service', to: 'pages#terms_of_service', as: :terms_of_service

  get '/activate/:id',              to: 'activations#create', as: :activation
  get '/register/:activation_code', to: 'activations#new',    as: :registration
  get 'tags/:tag',                  to: 'presentations#index', as: :tag

  # Provide redirects for legacy conference routes
  get "/conferences",         to: redirect(QueryRedirector.new("/events"))
  get 'conferences/upcoming', to: redirect('/events/upcoming')
  get "/conferences/chart",   to: redirect(QueryRedirector.new("/events/chart"))
  get 'conferences/:slug',    to: redirect('/events/%{slug}')

  namespace :api do
    resources :presentations
    resources :publications
    resources :speakers
  end

  resource  :account
  resources :events do
    collection do
      get :cities_count_by    # the chart data endpoint - returns JSON
      get :chart              # queries the data, renders the chart
      get :upcoming           # for the landing page
    end
    resources :supplements, except: [:index] do
      member do
        get :download
      end
    end
  end
  resources :event_users, only: [:index, :create, :destroy]
  resources :documents do
    member do
      get :download
    end
  end
  resources :languages
  resources :passages
  resources :presentation_publications, only: [:create, :destroy]
  resources :presentation_speakers, only: [:create, :destroy]
  resources :presentations do
    member do
      get :manage_speakers, :manage_publications, :manage_related, :download_handout
    end
    collection do
      get :chart                     # queries the data and pushes it to the chart in an array
      get :tags
    end
  end
  resources :publications do
    collection do
      get :chart                     # queries the data and pushes it to the chart in an array
      get :latest                    # for the landing page
    end
  end
  resources :publishers, except: [:new, :show]
  resources :password_resets, only: [:new, :create, :edit, :update]
  resources :organizers
  resources :relations, only: [:new, :create, :destroy]
  resources :settings, only: [:index, :show, :edit, :update]
  resources :speakers do
    collection do
      get :presentations_count_by    # the chart data endpoint - returns JSON
      get :chart                     # queries the data and pushes it to the chart in an array
    end
  end
  resources :supplements, only: [:index]    # the supplements dashboard, outside the event context
  resources :users do
    member do
      patch :approve
    end
    collection do
      get   :events
      get   :names
      get   :summary
      get   :supporters
      get   :systat
    end
  end
  resources :user_presentations, only: [:index, :create, :update, :destroy] do
    collection do
      get :most_watched
      get :most_anticipated
      get :notifications
    end
  end
  resources :user_sessions, only: [:new, :create, :destroy]
end
