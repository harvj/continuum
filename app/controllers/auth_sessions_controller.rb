class AuthSessionsController < ActionController::Base
  include ContinuumSessionAccess
  protect_from_forgery with: :exception
  skip_forgery_protection only: %i[prepare bootstrap]
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
    write_opaque_cookie(ATTEMPT_COOKIE, browser, expires)
    prepare_next_host(attempt)
  end

  def prepare
    digest = posted_ticket_digest
    attempt = ContinuumOidcAttempt.find_by(prepare_digest: digest)
    return head :bad_request unless attempt

    browser = SecureRandom.hex(32)
    attempt.with_lock do
      index = attempt.receiver_bindings.size + 1
      chain = session_hosts(attempt.host)
      unless chain[index] == request.host && request.origin == "https://#{chain[index - 1]}" &&
          attempt.prepare_digest == digest && attempt.prepare_expires_at&.future? && attempt.expires_at.future?
        raise ContinuumAuth::Invalid
      end

      attempt.update!(receiver_bindings: attempt.receiver_bindings.merge(request.host => Digest::SHA256.hexdigest(browser)),
        prepare_digest: nil, prepare_expires_at: nil)
    end
    write_opaque_cookie(RECEIVER_COOKIE, browser, attempt.expires_at)
    prepare_next_host(attempt)
  rescue ContinuumAuth::Invalid, ActiveRecord::RecordNotFound
    head :bad_request
  end

  def start
    return head :no_content unless deliberate_navigation?

    browser = cookies[ATTEMPT_COOKIE]
    return head :bad_request unless browser && OPAQUE.match?(browser)

    attempt = ContinuumOidcAttempt.find_by(host: request.host, client_id: auth_registration.id,
      browser_digest: Digest::SHA256.hexdigest(browser))
    return head :bad_request unless attempt

    attempt.with_lock do
      unless !attempt.started? && attempt.expires_at.future? &&
          attempt.receiver_bindings.keys.sort == (ContinuumAuth::HOSTS - [request.host]).sort
        raise ContinuumAuth::Invalid
      end

      attempt.update!(started: true)
    end
    redirect_to auth_provider.authorization_url(attempt), allow_other_host: true
  rescue ContinuumAuth::Invalid, ActiveRecord::RecordNotFound
    head :bad_request
  rescue ContinuumAuth::Unavailable
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
    previous = stored_session
    record = ContinuumSession.transaction do
      ContinuumSession.where(expires_at: ...Time.current).delete_all
      session = ContinuumSession.create!(host: request.host, client_id: auth_registration.id, active: false,
        token_digest: Digest::SHA256.hexdigest(token), subject: identity.subject, username:,
        encrypted_grant: ContinuumSession.encrypt(identity.grant), expires_at: identity.expires_at)
      attempt.receiver_bindings.each do |host, browser_digest|
        session.continuum_session_handles.create!(host:, browser_digest:)
      end
      session
    end
    retire_session(previous)
    reset_session
    write_opaque_cookie(SESSION_COOKIE, token, identity.expires_at)
    continue_sign_in(record)
  rescue ContinuumAuth::Invalid, ArgumentError
    head :bad_request
  rescue ContinuumAuth::Unavailable
    head :service_unavailable
  end

  def bootstrap
    digest = posted_ticket_digest
    browser = cookies[RECEIVER_COOKIE]
    return head :bad_request unless browser && OPAQUE.match?(browser)

    handle = ContinuumSessionHandle.find_by(host: request.host, ticket_digest: digest)
    return head :bad_request unless handle

    old_session = stored_session
    token = SecureRandom.hex(32)
    record = handle.continuum_session
    record.with_lock do
      handle.reload
      chain = session_hosts(record.host)
      index = chain.index(request.host)
      unless index&.positive? && request.origin == "https://#{chain[index - 1]}" &&
          handle.ticket_digest == digest && handle.ticket_expires_at&.future? &&
          ActiveSupport::SecurityUtils.secure_compare(handle.browser_digest, Digest::SHA256.hexdigest(browser)) &&
          !record.active? && record.expires_at.future? && session_registration(record)
        raise ContinuumAuth::Invalid
      end

      handle.update!(ticket_digest: nil, ticket_expires_at: nil, token_digest: Digest::SHA256.hexdigest(token))
      record.update!(active: true) if index == chain.length - 1
    end
    retire_session(old_session)
    cookies.delete(RECEIVER_COOKIE, secure: true, path: "/")
    reset_session
    write_opaque_cookie(SESSION_COOKIE, token, record.expires_at)
    continue_sign_in(record)
  rescue ContinuumAuth::Invalid, ActiveRecord::RecordNotFound
    head :bad_request
  end

  def destinations
    record = resolve_session
    return head :unauthorized unless record && request.headers["X-Continuum-Shell"] == record.shell_context
    return head :no_content unless @grant_active

    evidence = session_provider(record).evidence(record.access_grant, subject: record.subject)
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
    retire_session(stored_session)
    cookies.delete(SESSION_COOKIE, secure: true, path: "/")
    cookies.delete(ATTEMPT_COOKIE, secure: true, path: "/")
    reset_session
    redirect_to "/", status: :see_other
  end

  private

  def retire_session(record)
    return unless record && ContinuumSession.where(id: record.id).delete_all == 1

    session_provider(record).revoke(record.access_grant)
  rescue ContinuumAuth::Unavailable, ContinuumAuth::Invalid, ActiveSupport::MessageEncryptor::InvalidMessage
    # All local handles are invalidated even during an Auth outage.
  end

  def session_hosts(origin)
    [origin, *(ContinuumAuth::HOSTS - [origin])]
  end

  def posted_ticket_digest
    ticket = request.request_parameters["ticket"]
    unless request.media_type == "application/x-www-form-urlencoded" && ticket.is_a?(String) && OPAQUE.match?(ticket)
      raise ContinuumAuth::Invalid
    end

    Digest::SHA256.hexdigest(ticket)
  end

  def prepare_next_host(attempt)
    next_host = session_hosts(attempt.host)[attempt.receiver_bindings.size + 1]
    return return_to_origin(attempt.host, "/auth/start") unless next_host

    ticket = SecureRandom.hex(32)
    attempt.update!(prepare_digest: Digest::SHA256.hexdigest(ticket),
      prepare_expires_at: [30.seconds.from_now, attempt.expires_at].min)
    render_handoff(next_host, "/auth/session/prepare", ticket)
  end

  def continue_sign_in(record)
    chain = session_hosts(record.host)
    next_host = chain[chain.index(request.host) + 1]
    return return_to_origin(record.host, "/") unless next_host

    ticket = SecureRandom.hex(32)
    record.continuum_session_handles.find_by!(host: next_host).update!(ticket_digest: Digest::SHA256.hexdigest(ticket),
      ticket_expires_at: [30.seconds.from_now, record.expires_at].min)
    render_handoff(next_host, "/auth/session", ticket)
  end

  def return_to_origin(host, path)
    @bootstrap_return = "https://#{host}#{path}"
    render :bootstrap
  end

  def render_handoff(host, path, ticket)
    @bootstrap_ticket = ticket
    @bootstrap_target = "https://#{host}#{path}"
    # Send only the Origin for the next cross-origin POST. The ticket is never in a URL.
    response.headers["Referrer-Policy"] = "strict-origin"
    response.headers["Content-Security-Policy"] =
      "default-src 'none'; script-src 'self'; form-action https://#{host}; base-uri 'none'; frame-ancestors 'none'"
    render :bootstrap
  end

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
