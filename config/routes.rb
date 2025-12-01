Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  devise_for :users

  # API Routes for Flutter app
  namespace :api do
    namespace :v1 do
      # Categories
      resources :categories, only: [ :index, :show ] do
        member do
          get :products
        end
        collection do
          get :tree
          get :featured
        end
      end

      # Products
      resources :products, only: [ :index, :show ] do
        collection do
          get :search
          get :featured
          get :on_sale
          get :brands
          get "by_slug/:slug", to: "products#by_slug", as: :by_slug
        end
      end

      # Site Settings
      resources :site_settings, only: [ :index ], param: :key do
        collection do
          get :homepage
          get :app_config
        end
      end
      get "site_settings/:key", to: "site_settings#show", as: :site_setting
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#home"
end
