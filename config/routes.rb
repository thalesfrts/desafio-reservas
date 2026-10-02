Rails.application.routes.draw do
  get "reservations/index"
  get "reservations/new"
  get "reservations/create"
  get "reservations/destroy"
  resources :tickets, except: [ :edit ] do
    resources :comments, only: [ :create ]
  end
  resources :ticket_statuses, except: [ :show ]
  resources :ticket_types, except: [ :show ]
  resources :blocks, except: [ :show ]
  resources :reservations, only: [ :index, :new, :create, :destroy ]
  resources :notifications, only: [ :index, :update ] do
    patch :mark_all_as_read, on: :collection
    delete :destroy_all, on: :collection
  end
  devise_for :users, skip: [ :registrations, :passwords ], controllers: { sessions: "users/sessions" }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  namespace :admin do
    get "reservations/index"
    get "reservations/approve"
    get "reservations/deny"
    resources :users
    resources :user_units, only: [ :index, :create, :destroy ]
    resources :audit_logs, only: [ :index, :show ]
    get "units", to: "units#index"
    resources :areas
    resources :reservations, only: [ :index, :destroy ] do
      member do
        patch :approve
        patch :deny
      end
    end
  end

  # Defines the root path route ("/")
  devise_scope :user do
    authenticated :user do
      root to: "tickets#index", as: :authenticated_root
    end

    unauthenticated do
      root to: "users/sessions#new", as: :unauthenticated_root
    end
  end
end
