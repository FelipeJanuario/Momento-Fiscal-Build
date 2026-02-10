# frozen_string_literal: true

# Read the pfx file and get the private key and certificate
# rubocop:disable Metrics/ClassLength, Metrics/MethodLength, Metrics/AbcSize:
class AuthenticatePjeService
  BASE_URL     = "https://sso.cloud.pje.jus.br"
  REDIRECT_URL = "https://portaldeservicos.pdpj.jus.br/consulta"
  LOGIN_URL    = "https://sso.cloud.pje.jus.br/auth/realms/pje/protocol/openid-connect/auth?client_id=portalexterno-frontend&redirect_uri=https%3A%2F%2Fportaldeservicos.pdpj.jus.br%2Fconsulta&response_type=code&scope=openid"

  def initialize(
    pje_pfx: ENV.fetch("PJE_AUTH_PFX", nil),
    pje_cert_chain: ENV.fetch("PJE_AUTH_CERTCHAIN", nil),
    password: ENV.fetch("PJE_AUTH_PFX_PASSWORD", nil)
  )
    @pje_pfx = pje_pfx
    @pje_cert_chain = pje_cert_chain
    @password = password
    @cookie_header = nil
    @tab_id = nil

    validate_args
  end

  def validate_args
    raise ArgumentError, "pje_pfx or PJE_AUTH_PFX environment variable is required" if @pje_pfx.empty?
    raise ArgumentError, "password or PJE_AUTH_PFX_PASSWORD environment variable is required" if @password.empty?

    return unless @pje_cert_chain.empty?

    raise ArgumentError,
          "pje_cert_chain or PJE_AUTH_CERTCHAIN environment variable is required"
  end

  # Authenticate in PJE and get the JWT token
  # @return [String] The JWT token
  def call
    Rails.logger.debug("[AuthenticatePjeService] Fetching auth params")

    params = fetch_auth_params

    Rails.logger.debug("[AuthenticatePjeService] Signing the authentication challenge")

    signed_data = sign_pje_message(params)

    Rails.logger.debug("[AuthenticatePjeService] Sending the signed data")

    send_signature(params, signed_data)

    Rails.logger.debug("[AuthenticatePjeService] Authenticating with signature")

    code = authenticate_with_signature(params, signed_data)

    Rails.logger.debug("[AuthenticatePjeService] Authorizing with code")

    jwt = authorize_with_code(code)

    Rails.logger.info("[AuthenticatePjeService] Authorized successfully")

    jwt
  end

  private

  def fetch(uri_str, limit = 10)
    # You should choose a better exception.
    raise ArgumentError, "too many HTTP redirects" if limit.zero?

    Rails.logger.debug { "[AuthenticatePjeService][fetch] Fetching #{uri_str}" }

    response = Net::HTTP.get_response(URI(uri_str)) do |http|
      http["Cookie"] = @cookie_header if @cookie_header
    end

    @cookie_header = response["set-cookie"] if response["set-cookie"]

    Rails.logger.debug { "[AuthenticatePjeService][fetch] Response status code: #{response.code}" }

    case response
    when Net::HTTPSuccess
      response
    when Net::HTTPRedirection
      location = response["location"]
      warn "redirected to #{location}"
      fetch(location, limit - 1)
    else
      response.value
    end
  end

  def find_tab_id(response)
    return if response["location"].nil?

    @find_tab_id ||= response["location"].match(/tab_id=([^&]+)/)[1]
  end

  def generate_random_chars(length)
    chars = ("a".."z").to_a + ("0".."9").to_a
    Array.new(length) { chars.sample }.join
  end

  def fetch_auth_params
    response = fetch(LOGIN_URL)
    message = "0.#{generate_random_chars(10)}"
    token = SecureRandom.uuid
    find_tab_id(response)
    page = Nokogiri::HTML(response.body)
    codigo_seguranca = page.css("#kc-form-login .certificado a[onclick]").first["onclick"].match(/'([^']+)'/)[1]

    # Get the form data
    form = page.css("#kc-form-login").first
    @session_code = form["action"].match(/session_code=([^&]+)/)[1]
    @execution    = form["action"].match(/execution=([^&]+)/)[1]
    @client_id    = form["action"].match(/client_id=([^&]+)/)[1]
    @tab_id       = form["action"].match(/tab_id=([^&]+)/)[1]

    {
      sessao:          @cookie_header,
      aplicacao:       "PJe",
      servidor:        "#{BASE_URL}/auth/realms/pje",
      codigoSeguranca: codigo_seguranca,
      tarefaId:        "sso.autenticador",
      tarefa:          {
        enviarPara: "/pjeoffice-rest",
        mensagem:   message,
        token:      token
      }
    }
  end

  def keycloak_identity
    @cookie_header.split(";").find { |cookie| cookie.include?("KEYCLOAK_IDENTITY") }.split("=").last
  end

  def keycloak_identity_jwt_content
    JWT.decode(keycloak_identity, nil, false)[0]
  end

  # Sign the message with the private key from the pfx file
  def sign_pje_message(params)
    pfx_file = Base64.strict_decode64(@pje_pfx)
    pfx = OpenSSL::PKCS12.new(pfx_file, @password)
    key = pfx.key
    subject = pfx.certificate.subject.to_s(OpenSSL::X509::Name::COMPAT)

    Rails.logger.info("[AuthenticatePjeService] Signing message with key from #{subject}")

    # Sign the message using MD5 with RSA
    digest = OpenSSL::Digest.new("MD5")
    signature = key.sign(digest, params[:tarefa][:mensagem])

    # Encode the signature in base64
    Base64.strict_encode64(signature)
  end

  # Send the signature to PJE, enabling the user to authenticate
  def send_signature(params, signed_data)
    uri = URI("#{params[:servidor]}#{params[:tarefa][:enviarPara]}")
    req = Net::HTTP::Post.new(uri)
    req["Cookie"] = params[:sessao]
    req["versao"] = "2.5.16"
    req["Accept-Encoding"] = "gzip,deflate"
    req["Content-Type"] = "application/json"
    req["User-Agent"] = "Mozilla/5.0 (compatible; MyApp/1.0)"

    # Add the signed data to the request
    req.body = {
      "uuid"       => params[:tarefa][:token],
      "mensagem"   => params[:tarefa][:mensagem],
      "assinatura" => signed_data,
      "certChain"  => @pje_cert_chain
    }.to_json

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(req)
    end

    find_tab_id(res)

    raise "Failed to send signature: #{res.code} #{res.body}" unless res.is_a?(Net::HTTPSuccess)

    res
  end

  # Authenticate with the signature sent to PJE
  # @return [String] The authentication code
  def authenticate_with_signature(params, signed_data)
    args = URI.encode_www_form(
      client_id:    @client_id || "portalexterno-frontend",
      tab_id:       @tab_id,
      session_code: @session_code,
      execution:    @execution
    )

    uri = URI("#{BASE_URL}/auth/realms/pje/login-actions/authenticate?#{args}")

    Rails.logger.debug { "[AuthenticatePjeService][authenticate_with_signature] POST uri: #{uri}" }

    req = Net::HTTP::Post.new(uri)

    req["Origin"] = "https://portaldeservicos.pdpj.jus.br"
    req["Host"]   = "sso.cloud.pje.jus.br"
    req["Cookie"] = params[:sessao]

    req.set_form_data(
      username:         "",
      password:         "",
      credentialId:     "",
      "pjeoffice-code": params[:tarefa][:token],
      phrase:           params[:tarefa][:mensagem]
    )

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(req)
    end

    # In case the tab_id is not found, try to find it again
    if @tab_id.nil?
      find_tab_id(res)

      raise "Failed to find tab_id: #{res.code} #{res.body}" if @tab_id.nil?

      return authenticate_with_signature(params, signed_data)
    end

    code = res["Location"].match(/code=([^&]+)/)[1]
    @session_state = res["Location"].match(/session_state=([^&]+)/)[1]

    raise "Failed to authenticate with signature: #{res.code} #{res.body}" if code.blank?

    @cookie_header = res["set-cookie"] if res["set-cookie"]

    code
  end

  # Authorize the user on Keycloak with the authentication code
  # @return [String] The JWT token
  def authorize_with_code(code)
    uri = URI("#{BASE_URL}/auth/realms/pje/protocol/openid-connect/token")

    req = Net::HTTP::Post.new(uri)

    req["Accept-Encoding"] = "gzip,deflate"
    req["Content-Type"]    = "application/x-www-form-urlencoded"
    req["Origin"]          = "https://portaldeservicos.pdpj.jus.br"
    req["Host"]            = "sso.cloud.pje.jus.br"
    req["Cookie"]          = @cookie_header

    req.set_form_data(
      "grant_type"   => "authorization_code",
      "code"         => code,
      "client_id"    => @client_id || "portalexterno-frontend",
      "redirect_uri" => REDIRECT_URL
    )

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(req)
    end

    raise "Failed to authorize with code: #{res.code} #{res.body}" unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)["access_token"]
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/MethodLength, Metrics/AbcSize
