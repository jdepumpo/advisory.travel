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

ActiveRecord::Schema[8.1].define(version: 2026_11_06_030000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "advisories", force: :cascade do |t|
    t.bigint "country_id", null: false
    t.bigint "issuer_id", null: false
    t.integer "level"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "pub_date"
    t.string "source"
    t.string "summary"
    t.index ["country_id"], name: "index_advisories_on_country_id"
    t.index ["issuer_id"], name: "index_advisories_on_issuer_id"
  end

  create_table "countries", force: :cascade do |t|
    t.string "name"
    t.string "alpha2"
    t.string "region"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "subregion"
    t.string "capital"
    t.string "drives_on"
    t.integer "population"
    t.boolean "landlocked"
  end

  create_table "issuers", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "advisories", "countries"
  add_foreign_key "advisories", "issuers"
end
