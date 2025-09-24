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

ActiveRecord::Schema[8.0].define(version: 2025_09_24_112321) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "alerts", force: :cascade do |t|
    t.bigint "user_id"
    t.string "symbol", null: false
    t.string "direction", null: false
    t.decimal "threshold", precision: 30, scale: 10, null: false
    t.integer "check_interval_seconds", default: 60, null: false
    t.integer "cooldown_seconds", default: 300, null: false
    t.datetime "last_triggered_at"
    t.decimal "last_triggered_price", precision: 30, scale: 10
    t.datetime "next_check_at"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "channels", default: [], null: false, array: true
    t.index ["symbol"], name: "index_alerts_on_symbol"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end
end
