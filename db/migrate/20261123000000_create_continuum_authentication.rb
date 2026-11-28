class CreateContinuumAuthentication < ActiveRecord::Migration[8.1]
  def change
    create_table :continuum_oidc_attempts do |t|
      t.string :host, null: false
      t.string :client_id, null: false
      t.string :browser_digest, null: false
      t.string :state, null: false
      t.string :nonce, null: false
      t.string :verifier, null: false
      t.datetime :expires_at, null: false
      t.index :state, unique: true
      t.index :expires_at
    end

    create_table :continuum_sessions do |t|
      t.string :host, null: false
      t.string :client_id, null: false
      t.string :token_digest, null: false
      t.string :subject, null: false
      t.string :username
      t.text :encrypted_grant, null: false
      t.datetime :expires_at, null: false
      t.index :token_digest, unique: true
      t.index :expires_at
    end
  end
end
