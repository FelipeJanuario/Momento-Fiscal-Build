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

ActiveRecord::Schema[7.2].define(version: 2025_11_14_020341) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "allowlisted_jwts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "jti", null: false
    t.string "aud"
    t.datetime "exp", null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_allowlisted_jwts_on_jti", unique: true
    t.index ["user_id"], name: "index_allowlisted_jwts_on_user_id"
  end

  create_table "consulting_proposals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "consulting_id", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "comment"
    t.string "services"
    t.index ["consulting_id"], name: "index_consulting_proposals_on_consulting_id"
  end

  create_table "consultings", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.decimal "value", precision: 15, scale: 2, null: false
    t.time "sent_at", null: false
    t.uuid "client_id"
    t.uuid "consultant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_favorite", default: false
    t.string "import_hash"
    t.integer "debts_count"
    t.index ["client_id"], name: "index_consultings_on_client_id"
    t.index ["consultant_id"], name: "index_consultings_on_consultant_id"
    t.index ["import_hash"], name: "index_consultings_on_import_hash", unique: true
  end

  create_table "free_plan_usages", force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "status", default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_free_plan_usages_on_user_id", unique: true
  end

  create_table "google_subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "subscription_id"
    t.string "purchase_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_google_subscriptions_on_user_id"
  end

  create_table "institutions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "cnpj", limit: 14, null: false
    t.string "responsible_name", null: false
    t.string "responsible_cpf", null: false
    t.string "email", null: false
    t.string "phone", null: false
    t.string "cell_phone", null: false
    t.decimal "limit_debt", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cnpj"], name: "index_institutions_on_cnpj", unique: true
  end

  create_table "invitations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email"
    t.integer "status", default: 0
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["email"], name: "index_invitations_on_email", unique: true
    t.index ["user_id"], name: "index_invitations_on_user_id"
  end

  create_table "notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "title"
    t.string "content"
    t.string "redirect_to"
    t.time "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "user_institutions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "role", default: 0, null: false
    t.uuid "user_id", null: false
    t.uuid "institution_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["institution_id"], name: "index_user_institutions_on_institution_id"
    t.index ["user_id"], name: "index_user_institutions_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "cpf", limit: 120, default: "", null: false
    t.date "birth_date", null: false
    t.string "name", default: "", null: false
    t.string "phone", limit: 120, default: "", null: false
    t.integer "sex", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "oab_subscription", limit: 15
    t.string "oab_state", limit: 2
    t.boolean "admin", default: false
    t.integer "role", default: 0, null: false
    t.string "stripe_customer_id"
    t.boolean "ios_plan", default: false, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["cpf"], name: "index_users_on_cpf", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["oab_subscription", "oab_state"], name: "index_users_on_oab_subscription_and_oab_state"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "allowlisted_jwts", "users", on_delete: :cascade
  add_foreign_key "consulting_proposals", "consultings"
  add_foreign_key "consultings", "users", column: "client_id"
  add_foreign_key "consultings", "users", column: "consultant_id"
  add_foreign_key "free_plan_usages", "users"
  add_foreign_key "google_subscriptions", "users"
  add_foreign_key "invitations", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "user_institutions", "institutions"
  add_foreign_key "user_institutions", "users"
end
