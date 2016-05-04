# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160504020452) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "craigslist_postings", force: :cascade do |t|
    t.string  "url"
    t.string  "reply_type"
    t.text    "scrape_contents"
    t.string  "email_address"
    t.string  "subject_line"
    t.string  "base_url"
    t.boolean "recaptcha"
    t.integer "craigslist_scrape_id"
  end

  create_table "craigslist_scrapes", force: :cascade do |t|
    t.string "url"
    t.text   "scrape_contents"
    t.string "location_string"
    t.string "search_string"
    t.text   "postings_urls"
  end

  create_table "photographer_lists", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.text   "scrape_contents"
  end

  create_table "proxies", force: :cascade do |t|
    t.string   "protocol"
    t.string   "ip_address"
    t.string   "port"
    t.boolean  "bad"
    t.integer  "bad_count"
    t.integer  "good_count"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "country"
    t.integer  "code_403_count"
    t.integer  "code_500_count"
  end

end
