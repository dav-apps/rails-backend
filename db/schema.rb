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

ActiveRecord::Schema.define(version: 20180504175456) do

  create_table "access_tokens", force: :cascade do |t|
    t.string   "token",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "apps", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.text     "description",  limit: 65535
    t.integer  "dev_id",       limit: 4
    t.boolean  "published",                  default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "link_web",     limit: 255
    t.string   "link_play",    limit: 255
    t.string   "link_windows", limit: 255
  end

  create_table "archives", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",       limit: 255
    t.boolean  "completed",              default: false
  end

  create_table "devs", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "api_key",    limit: 255
    t.string   "secret_key", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid",       limit: 255
  end

  create_table "event_logs", force: :cascade do |t|
    t.integer  "event_id",   limit: 4
    t.datetime "created_at"
  end

  create_table "events", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "app_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "properties", force: :cascade do |t|
    t.integer "table_object_id", limit: 4
    t.string  "name",            limit: 255
    t.string  "value",           limit: 255
  end

  create_table "table_objects", force: :cascade do |t|
    t.integer  "table_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",    limit: 4
    t.integer  "visibility", limit: 4,   default: 0
    t.string   "uuid",       limit: 255
    t.boolean  "file",                   default: false
  end

  create_table "table_objects_access_tokens", force: :cascade do |t|
    t.integer "table_object_id", limit: 4
    t.integer "access_token_id", limit: 4
  end

  create_table "tables", force: :cascade do |t|
    t.integer  "app_id",     limit: 4
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "old_email",                   limit: 255
    t.integer  "plan",                        limit: 4,   default: 0
    t.string   "stripe_customer_id",          limit: 255
    t.datetime "period_end"
    t.integer  "subscription_status",         limit: 4,   default: 0
  end

  create_table "users_apps", force: :cascade do |t|
    t.integer "user_id", limit: 4
    t.integer "app_id",  limit: 4
  end

end
