class AuthSessionsController < ActionController::Base
  include ContinuumSessionAccess
  protect_from_forgery with: :exception
  before_action :private_response
  before_action :require_registration

  def login
    return head :no_content unless deliberate_navigation?
    return redirect_to "/" if resolve_session && @grant_active

    reset_session
    browser = SecureRandom.hex(32)
    expires = 5.minutes.from_now
    ContinuumOidcAttempt.where(host: request.host, expires_at: ...Time.current).delete_all
    attempt = ContinuumOidcAttempt.create!(host: request.host, client_id: auth_registration.id,
      browser_digest: Digest::SHA256.hexdigest(browser), state: SecureRandom.hex(32),
      nonce: SecureRandom.hex(32), verifier: SecureRandom.urlsafe_base64(64), expires_at: expires)
    url = auth_provider.authorization_url(attempt)
    write_opaque_cookie(ATTEMPT_COOKIE, browser, expires)
    redirect_to url, allow_other_host: true
  rescue ContinuumAuth::Unavailable, ContinuumAuth::Invalid
    attempt&.destroy!
    head :service_unavailable
  end

  def callback
    state, code, error = callback_parameters
    browser = cookies[ATTEMPT_COOKIE]
    raise ContinuumAuth::Invalid unless OPAQUE.match?(state) && browser && OPAQUE.match?(browser)

    attempt = ContinuumOidcAttempt.consume(state:, host: request.host, client_id: auth_registration.id,
      browser_digest: Digest::SHA256.hexdigest(browser))
    raise ContinuumAuth::Invalid unless attempt

    cookies.delete(ATTEMPT_COOKIE, secure: true, path: "/")
    raise ContinuumAuth::Invalid unless code.present? && error.nil?

    identity = auth_provider.exchange(code, attempt)
    raise ContinuumAuth::Invalid unless auth_provider.active?(identity.grant, subject: identity.subject)

    username = optional_username(identity)
    token = SecureRandom.hex(32)
    ContinuumSession.transaction do
      stored_session&.destroy!
      ContinuumSession.where(host: request.host, expires_at: ...Time.current).delete_all
      ContinuumSession.create!(host: request.host, client_id: auth_registration.id,
        token_digest: Digest::SHA256.hexdigest(token), subject: identity.subject, username:,
        encrypted_grant: ContinuumSession.encrypt(identity.grant), expires_at: identity.expires_at)
    end
    reset_session
    write_opaque_cookie(SESSION_COOKIE, token, identity.expires_at)
    redirect_to "/", status: :see_other
  rescue ContinuumAuth::Invalid, ArgumentError
    head :bad_request
  rescue ContinuumAuth::Unavailable
    head :service_unavailable
  end

  def destinations
    record = resolve_session
    return head :unauthorized unless record && request.headers["X-Continuum-Shell"] == record.shell_context
    return head :no_content unless @grant_active

    evidence = auth_provider.evidence(record.access_grant, subject: record.subject)
    return head :no_content unless evidence

    fresh = ContinuumSession.where(id: record.id).where("expires_at > ?", Time.current)
    return head :unauthorized unless fresh.update_all(username: evidence.username) == 1

    expires = [evidence.expires_at, record.expires_at].min
    return head :no_content unless expires.future?

    registry = Rails.application.config.x.shell_registry
    render json: { username: evidence.username, ttl_ms: ((expires - Time.current) * 1000).floor,
      destinations: registry.destinations(evidence.destinations) }
  rescue ContinuumAuth::Unavailable, ContinuumAuth::Invalid, ActiveSupport::MessageEncryptor::InvalidMessage
    head :no_content
  end

  def destroy
    record = stored_session
    record&.destroy!
    cookies.delete(SESSION_COOKIE, secure: true, path: "/")
    cookies.delete(ATTEMPT_COOKIE, secure: true, path: "/")
    reset_session
    begin
      auth_provider.revoke(record.access_grant) if record
    rescue ContinuumAuth::Unavailable, ContinuumAuth::Invalid, ActiveSupport::MessageEncryptor::InvalidMessage
      # Local logout remains complete during an Auth outage.
    end
    redirect_to "/", status: :see_other
  end

  private

  def optional_username(identity)
    auth_provider.evidence(identity.grant, subject: identity.subject)&.username
  rescue ContinuumAuth::Unavailable, ContinuumAuth::Invalid
    nil
  end

  def deliberate_navigation?
    request.headers["Sec-Fetch-Mode"].in?([nil, "navigate"]) &&
      request.headers["Sec-Fetch-Dest"].in?([nil, "document"]) &&
      [request.headers["Purpose"], request.headers["Sec-Purpose"]].none? { |value| value.to_s.include?("prefetch") }
  end

  def callback_parameters
    raise ContinuumAuth::Invalid if request.query_string.bytesize > 8192

    values = {}
    URI.decode_www_form(request.query_string).each do |key, value|
      raise ContinuumAuth::Invalid if values.key?(key) || key.match?(/\A(?:state|code|error)\[/)
      values[key] = value
    end
    values.values_at("state", "code", "error")
  end

  def require_registration
    head :not_found unless auth_registration
  end

  def private_response
    response.headers["Cache-Control"] = "no-store"
    response.headers["Referrer-Policy"] = "no-referrer"
  end
end
