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

ActiveRecord::Schema[8.1].define(version: 2026_02_03_155156) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "mode", ["UPI", "CARD", "NETBANKING"]
  create_enum "transaction_decision", ["ALLOW", "FLAG", "BLOCK"]
  create_enum "trigger_factors", ["AMOUNT_DEVIATION", "FREQUENCY_SPIKE", "NEW_MODE", "TIME_ANOMALY"]

  create_table "transactions", force: :cascade do |t|
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.integer "amount_deviation_score", null: false
    t.datetime "created_at", null: false
    t.enum "decision", null: false, enum_type: "transaction_decision"
    t.integer "frequency_deviation_score", null: false
    t.enum "mode", null: false, enum_type: "mode"
    t.integer "mode_deviation_score", null: false
    t.integer "risk_score", null: false
    t.integer "time_deviation_score", null: false
    t.enum "triggered_factors", default: [], null: false, array: true, enum_type: "trigger_factors"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_transactions_on_created_at"
    t.index ["decision"], name: "index_transactions_on_decision"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "user_behavior_profiles", primary_key: "user_id", id: :serial, force: :cascade do |t|
    t.integer "allowed_transactions", default: 0, null: false
    t.integer "average_number_of_transactions_per_day"
    t.decimal "average_transaction_amount", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.decimal "max_transaction_amount_seen", precision: 15, scale: 2
    t.enum "registered_payment_modes", default: [], null: false, array: true, enum_type: "mode"
    t.integer "total_transactions", default: 0, null: false
    t.datetime "updated_at", null: false
    t.time "usual_transaction_end_hour"
    t.time "usual_transaction_start_hour"
    t.index ["user_id"], name: "index_user_behavior_profiles_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "jti", null: false
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "transactions", "users", on_delete: :cascade
  add_foreign_key "user_behavior_profiles", "users", on_delete: :cascade
end
