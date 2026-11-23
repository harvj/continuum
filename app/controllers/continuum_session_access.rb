module ContinuumSessionAccess
  SESSION_COOKIE = "__Host-continuum-session".freeze
  ATTEMPT_COOKIE = "__Host-continuum-oidc".freeze
  OPAQUE = /\A[0-9a-f]{64}\z/

  private

  def auth_registration
    Rails.application.config.x.auth_registrations[request.host]
  end

  def auth_provider
    @auth_provider ||= Rails.application.config.x.auth_provider.call(auth_registration)
  end

  def stored_session
    token = cookies[SESSION_COOKIE]
    return unless auth_registration && token.is_a?(String) && OPAQUE.match?(token)

    ContinuumSession.where("expires_at > ?", Time.current).find_by(
      host: request.host, client_id: auth_registration.id, token_digest: Digest::SHA256.hexdigest(token))
  end

  def resolve_session
    record = stored_session
    return unless record

    begin
      unless auth_provider.active?(record.access_grant, subject: record.subject)
        record.destroy!
        cookies.delete(SESSION_COOKIE, secure: true, path: "/")
        return
      end
      @grant_active = true
    rescue ContinuumAuth::Unavailable, ContinuumAuth::Invalid
      # Keep the previously verified identity through an outage until its local
      # deadline. Release no authorization evidence from this request.
    rescue ActiveSupport::MessageEncryptor::InvalidMessage
      record.destroy!
      cookies.delete(SESSION_COOKIE, secure: true, path: "/")
      return
    end
    record if record.expires_at.future? && ContinuumSession.exists?(record.id)
  rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::ConnectionTimeoutError
    nil
  end

  def write_opaque_cookie(name, value, expiry)
    cookies[name] = { value:, expires: expiry, secure: true, httponly: true, same_site: :lax, path: "/" }
  end
end
