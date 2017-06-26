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

ActiveRecord::Schema.define(version: 20170626165503) do

  create_table "cards", force: :cascade do |t|
    t.string  "page1",   limit: 255
    t.string  "page2",   limit: 255
    t.integer "deck_id", limit: 4
  end

  create_table "decks", force: :cascade do |t|
    t.string  "name",    limit: 255
    t.integer "user_id", limit: 4
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                       limit: 255
    t.string   "password_digest",             limit: 255
    t.string   "username",                    limit: 255
    t.boolean  "confirmed",                               default: false
    t.string   "email_confirmation_token",    limit: 255
    t.string   "password_confirmation_token", limit: 255
    t.string   "new_password",                limit: 255
    t.string   "new_email",                   limit: 255
    t.string   "avatar_file_extension",       limit: 255
    t.boolean  "uses_cards",                              default: false
    t.boolean  "uses_usb",                                default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "old_email",                   limit: 255
  end

end
