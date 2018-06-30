# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_06_30_045547) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "conference_users", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "conference_id"
    t.bigint "creator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conference_id"], name: "index_conference_users_on_conference_id"
    t.index ["creator_id"], name: "index_conference_users_on_creator_id"
    t.index ["user_id"], name: "index_conference_users_on_user_id"
  end

  create_table "conferences", force: :cascade do |t|
    t.date "start_date"
    t.date "end_date"
    t.string "venue"
    t.string "venue_url"
    t.string "city"
    t.string "state"
    t.bigint "organizer_id"
    t.bigint "creator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_conferences_on_creator_id"
    t.index ["organizer_id"], name: "index_conferences_on_organizer_id"
  end

  create_table "friendly_id_slugs", id: :serial, force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "organizers", force: :cascade do |t|
    t.string "name"
    t.string "series_name"
    t.string "abbreviation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "presentation_speakers", force: :cascade do |t|
    t.bigint "presentation_id"
    t.bigint "speaker_id"
    t.bigint "creator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_presentation_speakers_on_creator_id"
    t.index ["presentation_id", "speaker_id"], name: "index_presentation_speakers_on_presentation_id_and_speaker_id", unique: true
    t.index ["presentation_id"], name: "index_presentation_speakers_on_presentation_id"
    t.index ["speaker_id"], name: "index_presentation_speakers_on_speaker_id"
  end

  create_table "presentations", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "conference_id"
    t.bigint "creator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parts"
    t.integer "duration"
    t.index ["conference_id"], name: "index_presentations_on_conference_id"
    t.index ["creator_id"], name: "index_presentations_on_creator_id"
  end

  create_table "publications", force: :cascade do |t|
    t.bigint "presentation_id"
    t.bigint "creator_id"
    t.date "published_on"
    t.string "format"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_publications_on_creator_id"
    t.index ["presentation_id"], name: "index_publications_on_presentation_id"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "settings", id: :serial, force: :cascade do |t|
    t.boolean "require_account_approval", default: true
  end

  create_table "speakers", force: :cascade do |t|
    t.string "name"
    t.string "photo"
    t.bigint "creator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sortable_name"
    t.index ["creator_id"], name: "index_speakers_on_creator_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email"
    t.string "crypted_password"
    t.string "password_salt"
    t.string "persistence_token"
    t.string "perishable_token"
    t.integer "login_count", default: 0, null: false
    t.integer "failed_login_count", default: 0, null: false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string "current_login_ip"
    t.string "last_login_ip"
    t.boolean "active", default: false
    t.boolean "approved", default: false
    t.string "name"
    t.string "city"
    t.string "state"
    t.string "country"
    t.string "time_zone"
    t.string "photo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role_id"
    t.boolean "comment_notifications", default: false
  end

end
