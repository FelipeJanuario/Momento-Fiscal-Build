# frozen_string_literal: true

# Alternative PJE authentication using Resource Owner Password Grant
# This method uses username/password instead of digital certificate
class PjePasswordAuthService
  BASE_URL = "https://sso.cloud.pje.jus.br"
  TOKEN_URL = "#{BASE_URL}/auth/realms/pje/protocol/openid-connect/token"
  API_URL = ENV.fetch("PJE_API_URL", "https://api.pje.jus.br")

  def initialize(
    username: ENV.fetch("PJE_USERNAME", nil),
    password: ENV.fetch("PJE_PASSWORD", nil),
    client_id: ENV.fetch("PJE_CLIENT_ID", "portalexterno-frontend")
  )
    @username = username
    @password = password
    @client_id = client_id
    
    validate_credentials
  end

  def validate_credentials
    raise ArgumentError, "PJE_USERNAME is required" if @username.nil? || @username.empty?
    raise ArgumentError, "PJE_PASSWORD is required" if @password.nil? || @password.empty?
  end

  # Authenticate and get JWT token
  # @return [Hash] Token response with access_token, refresh_token, etc.
  def call
    Rails.logger.info("[PjePasswordAuth] Authenticating with username: #{@username}")

    uri = URI(TOKEN_URL)
    req = Net::HTTP::Post.new(uri)
    req["Content-Type"] = "application/x-www-form-urlencoded"

    req.set_form_data(
      "grant_type" => "password",
      "username" => @username,
      "password" => @password,
      "client_id" => @client_id,
      "scope" => "openid"
    )

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(req)
    end

    unless res.is_a?(Net::HTTPSuccess)
      error_body = JSON.parse(res.body) rescue { "error" => "unknown" }
      raise "Failed to authenticate: #{res.code} - #{error_body['error_description'] || error_body['error']}"
    end

    token_data = JSON.parse(res.body)
    
    Rails.logger.info("[PjePasswordAuth] Authentication successful! Token expires in: #{token_data['expires_in']}s")
    
    token_data
  end

  # Query processes by CPF using the obtained token
  # @param cpf_cnpj [String] CPF or CNPJ to search
  # @param options [Hash] Query options (tribunal, fields, etc.)
  # @return [Hash] Query results
  def query_processes(cpf_cnpj, options = {})
    token_data = call
    access_token = token_data["access_token"]

    # Build API query
    filter = "partes.cpf eq #{cpf_cnpj.gsub(/\D/, '')}"
    fields = options[:fields] || "numero,classe.nome,dataAjuizamento,assuntos,orgaoJulgador"
    
    query_params = {
      filter: filter,
      fields: fields,
      size: options[:size] || 50,
      page: options[:page] || 1
    }

    # Determine the correct API endpoint
    # The PJE API structure varies by tribunal
    # For now, we'll use a generic endpoint
    api_endpoint = "#{API_URL}/processos"
    
    uri = URI(api_endpoint)
    uri.query = URI.encode_www_form(query_params)

    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{access_token}"
    req["Accept"] = "application/json"

    Rails.logger.debug("[PjePasswordAuth] Querying: #{uri}")

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(req)
    end

    unless res.is_a?(Net::HTTPSuccess)
      error_msg = "API query failed: #{res.code} - #{res.body[0..200]}"
      Rails.logger.error("[PjePasswordAuth] #{error_msg}")
      raise error_msg
    end

    result = JSON.parse(res.body)
    
    Rails.logger.info("[PjePasswordAuth] Found #{result.dig('result', 'total') || 0} processes")
    
    result
  end
end
