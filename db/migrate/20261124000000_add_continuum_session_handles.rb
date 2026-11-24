class AddContinuumSessionHandles < ActiveRecord::Migration[8.1]
  def change
    add_column :continuum_oidc_attempts, :receiver_bindings, :jsonb, null: false, default: {}
    add_column :continuum_oidc_attempts, :prepare_digest, :string
    add_column :continuum_oidc_attempts, :prepare_expires_at, :datetime
    add_column :continuum_oidc_attempts, :started, :boolean, null: false, default: false
    add_index :continuum_oidc_attempts, :prepare_digest, unique: true
    add_column :continuum_sessions, :active, :boolean, null: false, default: true

    create_table :continuum_session_handles do |t|
      t.references :continuum_session, null: false, foreign_key: { on_delete: :cascade }
      t.string :host, null: false
      t.string :browser_digest, null: false
      t.string :token_digest
      t.string :ticket_digest
      t.datetime :ticket_expires_at
      t.index [:continuum_session_id, :host], unique: true
      t.index :token_digest, unique: true
      t.index :ticket_digest, unique: true
    end
  end
end
