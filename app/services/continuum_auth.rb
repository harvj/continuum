require "openid_connect"
require "net/http"
require "timeout"

class ContinuumAuth
  ISSUER = "https://auth.harvj.com".freeze
  USERNAME = /\A[a-z0-9][a-z0-9_-]{0,31}\z/
  DESTINATION = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/
  MAX_SESSION = 5.minutes
  Registration = Data.define(:host, :id, :secret, :assurance) do
    def callback
      "https://#{host}/auth/callback"
    end
  end
  Identity = Data.define(:subject, :grant, :expires_at)
  Evidence = Data.define(:username, :destinations, :expires_at)
  class Unavailable < StandardError; end
  class Invalid < StandardError; end

  OpenIDConnect.http_config do |http|
    http.options.open_timeout = 2
    http.options.timeout = 3
  end

  def self.registrations(raw)
    data = JSON.parse(raw, allow_duplicate_key: false)
    raise ArgumentError, "Invalid Continuum Auth registrations" unless data.is_a?(Hash)

    data.each_with_object({}) do |(host, entry), result|
      unless host.in?(%w[network.harvj.com library.harvj.com intelligence.harvj.com]) &&
        entry.is_a?(Hash) && entry["client_id"].is_a?(String) && entry["client_id"].present? &&
        entry["client_secret"].is_a?(String) && entry["client_secret"].present? &&
        (entry["required_acr"].nil? || entry["required_acr"].is_a?(String))
        raise ArgumentError, "Invalid Continuum Auth registration"
      end

      result[host] = Registration.new(host, entry.fetch("client_id"), entry.fetch("client_secret"),
        entry["required_acr"].presence)
    end.freeze
  rescue JSON::ParserError, NoMethodError, TypeError
    raise ArgumentError, "Invalid Continuum Auth registrations"
  end

  def initialize(registration)
    @registration = registration
  end

  def authorization_url(attempt)
    with_provider do
      client.authorization_uri(scope: ["openid"], response_type: :code, state: attempt.state,
        nonce: attempt.nonce, code_challenge_method: "S256",
        code_challenge: Base64.urlsafe_encode64(Digest::SHA256.digest(attempt.verifier), padding: false))
    end
  end

  def exchange(code, attempt)
    with_provider do
      client.authorization_code = code
      token = client.access_token!(code_verifier: attempt.verifier, client_auth_method: :basic)
      header = JSON::JWT.decode(token.id_token, :skip_verification)
      raise Invalid unless header.algorithm.to_s == "RS256" && header.kid.present?

      identity = OpenIDConnect::ResponseObject::IdToken.decode(token.id_token, discovery)
      identity.verify!(issuer: ISSUER, client_id: @registration.id, nonce: attempt.nonce)
      unless identity.sub.present? && identity.iat.is_a?(Integer) && identity.iat <= Time.current.to_i + 30 &&
        identity.exp.is_a?(Integer) &&
        (identity.azp.blank? || identity.azp == @registration.id) &&
        (Array(identity.aud).size == 1 || identity.azp == @registration.id) &&
        (!@registration.assurance || identity.acr == @registration.assurance)
        raise Invalid
      end

      grant = token.access_token
      lifetime = Integer(token.expires_in, exception: false)
      raise Invalid unless grant.is_a?(String) && grant.present? && lifetime&.positive?

      Identity.new(identity.sub, grant, [Time.at(identity.exp), [lifetime, MAX_SESSION.to_i].min.seconds.from_now].min)
    end
  end

  def active?(grant, subject:)
    response = introspect(grant)
    return false if response["active"] == false
    raise Unavailable unless response["active"] == true && response["client_id"].is_a?(String)

    response["client_id"] == @registration.id && (!response.key?("sub") || response["sub"] == subject)
  end

  def evidence(grant, subject:)
    response = introspect(grant, "application_shell_version" => "1")
    return unless response["active"] == true

    data = response["application_shell"]
    return unless data.is_a?(Hash) &&
      data.values_at("version", "iss", "aud", "sub", "grant_binding") ==
        ["1", ISSUER, @registration.id, subject, Digest::SHA256.hexdigest(grant)]

    username, ids, issued, expires = data.values_at("preferred_username", "eligible_destination_ids", "iat", "exp")
    return unless username.is_a?(String) && USERNAME.match?(username) && ids.is_a?(Array) && ids.size <= 64 &&
      ids.uniq == ids && ids.all? { |id| id.is_a?(String) && id.bytesize <= 64 && DESTINATION.match?(id) } &&
      issued.is_a?(Integer) && expires.is_a?(Integer) &&
      issued <= Time.current.to_i && Time.current.to_i < expires && (expires - issued).between?(1, 60)

    Evidence.new(username, ids, Time.at(expires))
  end

  def revoke(grant)
    post(discovery_endpoint("revocation_endpoint", "/revoke")) do |request|
      # Auth distinguishes confidential JSON revocation from its browser form.
      request["Accept"] = "application/json"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(token: grant, token_type_hint: "access_token")
    end
  end

  private

  def introspect(grant, options = {})
    endpoint = discovery_endpoint("introspection_endpoint", "/introspect")
    body = post_form(endpoint, { token: grant, token_type_hint: "access_token" }.merge(options))
    data = JSON.parse(body, allow_duplicate_key: false)
    raise Unavailable unless data.is_a?(Hash)

    data
  rescue JSON::ParserError
    raise Unavailable
  end

  def post_form(endpoint, form)
    post(endpoint) { |request| request.set_form_data(form) }
  end

  def post(endpoint)
    with_provider do
      uri = URI(endpoint)
      http = Net::HTTP.new(uri.host, uri.port, nil)
      http.use_ssl = true
      http.open_timeout = 2
      http.read_timeout = 3
      http.write_timeout = 2
      request = Net::HTTP::Post.new(uri)
      request.basic_auth(@registration.id, @registration.secret)
      yield request
      response = http.request(request)
      raise Unavailable unless response.is_a?(Net::HTTPSuccess)

      response.body
    end
  end

  def discovery_endpoint(field, fallback)
    with_provider { validate_endpoint(discovery.raw[field] || "#{ISSUER}#{fallback}") }
  end

  def discovery
    @discovery ||= OpenIDConnect::Discovery::Provider::Config.discover!(ISSUER).tap do |server|
      raise Invalid unless server.issuer == ISSUER

      [server.authorization_endpoint, server.token_endpoint, server.jwks_uri].each { |url| validate_endpoint(url) }
    end
  end

  def validate_endpoint(url)
    uri = URI(url)
    raise Invalid unless uri.scheme == "https" && uri.host == URI(ISSUER).host && uri.port == 443 &&
      uri.userinfo.nil? && uri.query.nil? && uri.fragment.nil?

    url
  end

  def client
    @client ||= OpenIDConnect::Client.new(identifier: @registration.id, secret: @registration.secret,
      redirect_uri: @registration.callback, authorization_endpoint: discovery.authorization_endpoint,
      token_endpoint: discovery.token_endpoint)
  end

  def with_provider(&block)
    Timeout.timeout(5, &block)
  rescue OpenIDConnect::Exception, Rack::OAuth2::Client::Error, JSON::JWT::Exception, ArgumentError,
    Faraday::Error, Timeout::Error, SocketError, SystemCallError, IOError, OpenSSL::SSL::SSLError, URI::Error
    raise Unavailable
  end
end
