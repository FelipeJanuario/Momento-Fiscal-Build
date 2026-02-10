# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Em modo DEV (DEV_MODE=true), permite qualquer origem
    # Em produção (DEV_MODE=false), restringe para domínios específicos
    if ENV['DEV_MODE'] == 'true'
      origins '*'
      resource "*",
        headers: :any,
        methods: [:get, :post, :put, :patch, :delete, :options, :head],
        credentials: false  # false para wildcard origins
    else
      # Configure aqui os domínios permitidos em produção
      origins [
        'http://165.22.136.67',
        'https://momentofiscal.com.br',
        'https://www.momentofiscal.com.br',
        'https://app.momentofiscal.com.br'
      ]
      resource "*",
        headers: :any,
        methods: [:get, :post, :put, :patch, :delete, :options, :head],
        credentials: true  # true para domínios específicos
    end
  end
end
