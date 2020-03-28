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

ActiveRecord::Schema.define(version: 2020_03_21_191322) do

  create_table "access_tokens", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "active_app_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "app_id"
    t.datetime "time"
    t.integer "count_daily"
    t.integer "count_monthly"
    t.integer "count_yearly"
  end

  create_table "active_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.datetime "time"
    t.integer "count_daily"
    t.integer "count_monthly"
    t.integer "count_yearly"
  end

  create_table "api_endpoints", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "api_id"
    t.string "path"
    t.string "method"
    t.text "commands"
  end

  create_table "api_env_vars", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "api_id"
    t.string "name"
    t.string "value"
    t.string "class_name"
  end

  create_table "api_errors", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "api_id"
    t.integer "code"
    t.string "message"
  end

  create_table "api_functions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "api_id"
    t.string "name"
    t.string "params"
    t.text "commands"
  end

  create_table "apis", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "app_id"
    t.string "name"
  end

  create_table "apps", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "dev_id"
    t.boolean "published", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "link_web"
    t.string "link_play"
    t.string "link_windows"
  end

  create_table "archive_parts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "archive_id"
    t.string "name"
  end

  create_table "archives", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.boolean "completed", default: false
  end

  create_table "collections", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "table_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "devs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.string "api_key"
    t.string "secret_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "uuid"
  end

  create_table "event_log_properties", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "event_log_id"
    t.string "name"
    t.text "value"
  end

  create_table "event_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "event_id"
    t.datetime "created_at"
    t.boolean "processed", default: false
  end

  create_table "event_summaries", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "event_id"
    t.integer "period"
    t.datetime "time"
    t.integer "total", default: 0
  end

  create_table "event_summary_browser_counts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "standard_event_summary_id"
    t.string "name"
    t.string "version"
    t.integer "count", default: 0
  end

  create_table "event_summary_country_counts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "standard_event_summary_id"
    t.string "country"
    t.integer "count", default: 0
  end

  create_table "event_summary_os_counts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "standard_event_summary_id"
    t.string "name"
    t.string "version"
    t.integer "count", default: 0
  end

  create_table "event_summary_property_counts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "event_summary_id"
    t.string "name"
    t.text "value"
    t.integer "count", default: 0
  end

  create_table "events", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.integer "app_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notification_properties", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "notification_id"
    t.string "name"
    t.text "value"
  end

  create_table "notifications", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "app_id"
    t.integer "user_id"
    t.datetime "time"
    t.integer "interval"
    t.string "uuid"
  end

  create_table "platforms", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "app_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "properties", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "table_object_id"
    t.string "name"
    t.text "value"
  end

  create_table "providers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "user_id"
    t.string "stripe_account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "purchases", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "user_id"
    t.integer "table_object_id"
    t.string "payment_intent_id"
    t.string "product_image"
    t.string "product_name"
    t.string "provider_image"
    t.string "provider_name"
    t.integer "price"
    t.string "currency"
    t.boolean "completed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.integer "app_id"
    t.string "secret"
    t.datetime "exp"
    t.string "device_name"
    t.string "device_type"
    t.string "device_os"
    t.datetime "created_at"
  end

  create_table "standard_event_logs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "event_id"
    t.boolean "processed", default: false
    t.string "browser_name"
    t.string "browser_version"
    t.string "os_name"
    t.string "os_version"
    t.string "country"
    t.datetime "created_at"
  end

  create_table "standard_event_summaries", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "event_id"
    t.datetime "time"
    t.integer "period"
    t.integer "total", default: 0
  end

  create_table "table_object_collections", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "table_object_id"
    t.integer "collection_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "table_object_user_accesses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "table_object_id"
    t.integer "user_id"
    t.integer "table_alias"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "table_objects", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "table_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.integer "visibility", default: 0
    t.string "uuid"
    t.boolean "file", default: false
  end

  create_table "table_objects_access_tokens", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "table_object_id"
    t.integer "access_token_id"
  end

  create_table "table_objects_providers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "table_object_id"
    t.integer "provider_id"
  end

  create_table "tables", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "app_id"
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.string "username"
    t.boolean "confirmed", default: false
    t.string "email_confirmation_token"
    t.string "password_confirmation_token"
    t.string "new_password"
    t.string "new_email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "old_email"
    t.integer "plan", default: 0
    t.string "stripe_customer_id"
    t.datetime "period_end"
    t.integer "subscription_status", default: 0
    t.bigint "used_storage", default: 0
    t.datetime "last_active"
  end

  create_table "users_apps", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "app_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "used_storage", default: 0
    t.datetime "last_active"
  end

  create_table "web_push_subscriptions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.string "uuid"
    t.string "endpoint"
    t.string "p256dh"
    t.string "auth"
  end

end
