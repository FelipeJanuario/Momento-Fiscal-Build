Rails.application.routes.draw do
  devise_for(
    :users,
    class_name: 'User',
    path: "/api/v1/authentication/users",
    controllers: {
      sessions: "api/v1/users/sessions",
      registrations: "api/v1/users/registrations",
      passwords: "api/v1/users/passwords",
      confirmations: "api/v1/users/confirmations",
      unlocks: "api/v1/users/unlocks"
    }
  )

  namespace :api, defaults: { format: "json" } do
    namespace :v1 do
      resources :notifications, only: %i[index show destroy]
      resources :users
      resources :institutions
      resources :user_institutions
      resources :consultings
      post "consultings/:import_hash/import" => "consultings#import", as: :import_consultings
      get '/processes', to: 'processes#show', constraints: lambda { |req| req.params[:cpf_cnpj].present? || req.query_string.include?('cpf_cnpj') }
      get '/processes/:numero_processo', to: 'processes#show_by_number', constraints: { numero_processo: /\d{20}/ }
      get '/consulta_cpf/:cpf', to: 'serpro#consulta_cpf'
      get '/serpro/dividas/:cpf_cnpj', to: 'serpro#dividas'
      
      # Endpoint local de empresas (dados do banco + Serpro)
      resources :companies, only: [:index]
      resources :consulting_proposals
      resources :free_plan_usages, only: %i[index create update]
      resources :invitations, only: [:create] do
        collection do
          get 'check'
          put 'update_status'
        end
      end
      
      # Debtors (nossa base de CNPJs geocodificados)
      scope :debtors do
        get "nearby" => "debtors#nearby"
        get "nearby_cep" => "debtors#nearby_cep"
        post "batch_debts" => "debtors#batch_debts"
        get ":id/details" => "debtors#details"
        patch ":id/coordinates" => "debtors#update_coordinates"
      end

      scope :biddings_analyser do
        get "download" => "biddings_analyser#download"
        get "debts" => "biddings_analyser#debts"
        get 'debts/:cpf_cnpj/debts_per_debted_name', to: 'biddings_analyser#debts_per_debted_name'
        get "companies" => "biddings_analyser#companies"
        get "companies/count_in_location" => "biddings_analyser#count_companies_in_location"
        get "companies/in_location" => "biddings_analyser#companies_in_location"
      end

      # Mock endpoints for development (when BIDDINGS_ANALYSER_URL is not available)
      if ENV['DEV_MODE'] == 'true'
        scope :mock_biddings do
          get "count_in_location" => "mock_biddings#count_companies_in_location"
          get "in_location" => "mock_biddings#companies_in_location"
        end
      end

      scope :stripe do
        post "create_setup_intent" => "stripe#create_setup_intent"
        post "create_payment_intent" => "stripe#create_payment_intent"
        get "setup_intents" => "stripe#list_setup_intents"
        get "payment_methods" => "stripe#list_payment_methods"
        delete "payment_methods/:id" => "stripe#detach_payment_method"
        post "subscriptions" => "stripe#create_subscription"
        patch "subscriptions" => "stripe#update_subscription"
        get "subscriptions" => "stripe#list_subscriptions"
        get "current_subscription" => "stripe#current_subscription"
        get "enabled_features" => "stripe#enabled_features"
        delete "subscriptions/:id" => "stripe#cancel_subscription"
        get "products" => "stripe#list_products"
        get "products/:product_id/prices" => "stripe#list_prices"
      end

      scope :google do
        get "available_subscriptions" => "google/subscriptions#available_subscriptions"
        post "acknowledge_subscription" => "google/subscriptions#acknowledge_subscription"
      end
    end

    scope :health do
      get "up" => "health#show", as: :rails_health_check
    end
  end
end
