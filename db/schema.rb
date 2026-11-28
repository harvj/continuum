# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_24_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "continuum_oidc_attempts", force: :cascade do |t|
    t.string "host", null: false
    t.string "client_id", null: false
    t.string "browser_digest", null: false
    t.string "state", null: false
    t.string "nonce", null: false
    t.string "verifier", null: false
    t.datetime "expires_at", null: false
    t.jsonb "receiver_bindings", default: {}, null: false
    t.string "prepare_digest"
    t.datetime "prepare_expires_at"
    t.boolean "started", default: false, null: false
    t.index ["expires_at"], name: "index_continuum_oidc_attempts_on_expires_at"
    t.index ["prepare_digest"], name: "index_continuum_oidc_attempts_on_prepare_digest", unique: true
    t.index ["state"], name: "index_continuum_oidc_attempts_on_state", unique: true
  end

  create_table "continuum_session_handles", force: :cascade do |t|
    t.bigint "continuum_session_id", null: false
    t.string "host", null: false
    t.string "browser_digest", null: false
    t.string "token_digest"
    t.string "ticket_digest"
    t.datetime "ticket_expires_at"
    t.index ["continuum_session_id", "host"], name: "idx_on_continuum_session_id_host_5d3d34eb9d", unique: true
    t.index ["continuum_session_id"], name: "index_continuum_session_handles_on_continuum_session_id"
    t.index ["ticket_digest"], name: "index_continuum_session_handles_on_ticket_digest", unique: true
    t.index ["token_digest"], name: "index_continuum_session_handles_on_token_digest", unique: true
  end

  create_table "continuum_sessions", force: :cascade do |t|
    t.string "host", null: false
    t.string "client_id", null: false
    t.string "token_digest", null: false
    t.string "subject", null: false
    t.string "username"
    t.text "encrypted_grant", null: false
    t.datetime "expires_at", null: false
    t.boolean "active", default: true, null: false
    t.index ["expires_at"], name: "index_continuum_sessions_on_expires_at"
    t.index ["token_digest"], name: "index_continuum_sessions_on_token_digest", unique: true
  end

  add_foreign_key "continuum_session_handles", "continuum_sessions", on_delete: :cascade
end
