class ContinuumOidcAttempt < ActiveRecord::Base
  def self.consume(state:, host:, client_id:, browser_digest:)
    transaction do
      attempt = lock.find_by(state:, host:, client_id:, browser_digest:)
      if attempt
        attempt.destroy!
        attempt if attempt.expires_at.future?
      end
    end
  end
end
