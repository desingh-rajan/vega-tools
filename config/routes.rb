Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  devise_for :users

  # ==========================================================================
  # UNIFIED ROUTES - Serve both HTML (web) and JSON (API/Flutter)
  # Use `respond_to` in controllers to handle format
  # No API versioning complexity - keep it simple!
  # ==========================================================================

  # Products Catalog
  resources :products, only: [ :index, :show ], param: :slug do
    collection do
      get :search
      get :featured
      get :brands
    end
  end

  # Categories with nested products
  resources :categories, only: [ :index, :show ], param: :slug do
    member do
      get :products  # GET /categories/:slug/products
    end
    collection do
      get :tree      # GET /categories/tree (hierarchical)
      get :featured  # GET /categories/featured
    end
  end

  # Site Settings (public, read-only)
  resources :site_settings, only: [ :index, :show ], param: :key do
    collection do
      get :homepage   # GET /site_settings/homepage (all homepage settings)
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root
  root "pages#home"
end
