class ContinuumSession < ActiveRecord::Base
  def self.encrypt(grant)
    encryptor.encrypt_and_sign(grant, purpose: "auth-access-token")
  end

  def access_grant
    self.class.encryptor.decrypt_and_verify(encrypted_grant, purpose: "auth-access-token")
  end

  def shell_context
    Digest::SHA256.hexdigest("continuum-shell:#{token_digest}")
  end

  def self.encryptor
    cipher = "aes-256-gcm"
    key = Rails.application.key_generator.generate_key("continuum auth grants",
      ActiveSupport::MessageEncryptor.key_len(cipher))
    ActiveSupport::MessageEncryptor.new(key, cipher:)
  end
end
