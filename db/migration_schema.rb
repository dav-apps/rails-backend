# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_12_15_210915) do

  create_table "api_endpoint_request_cache_params", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "api_endpoint_request_cache_id"
    t.string "name"
    t.string "value"
  end

  create_table "api_endpoint_request_caches", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "api_endpoint_id"
    t.text "response"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "api_endpoints", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "api_id"
    t.string "path"
    t.string "method"
    t.text "commands"
    t.boolean "caching", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "api_env_vars", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "api_id"
    t.string "name"
    t.string "value"
    t.string "class_name"
  end

  create_table "api_errors", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "api_id"
    t.integer "code"
    t.string "message"
  end

  create_table "api_functions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "api_id"
    t.string "name"
    t.string "params"
    t.text "commands"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "apis", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "app_id"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "app_user_activities", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "app_id"
    t.datetime "time"
    t.integer "count_daily", default: 0
    t.integer "count_monthly", default: 0
    t.integer "count_yearly", default: 0
  end

  create_table "app_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "app_id"
    t.bigint "used_storage", default: 0
    t.datetime "last_active"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "apps", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "dev_id"
    t.string "name"
    t.string "description"
    t.boolean "published", default: false
    t.string "web_link"
    t.string "google_play_link"
    t.string "microsoft_store_link"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "collections", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "table_id"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "devs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.string "api_key"
    t.string "secret_key"
    t.string "uuid"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "exception_events", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "app_id"
    t.string "name"
    t.string "message"
    t.text "stack_trace"
    t.string "app_version"
    t.string "os_version"
    t.string "device_family"
    t.string "locale"
    t.datetime "created_at", precision: 6, null: false
  end

  create_table "notification_properties", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "notification_id"
    t.string "name"
    t.text "value"
  end

  create_table "notifications", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "app_id"
    t.string "uuid"
    t.datetime "time"
    t.integer "interval"
    t.datetime "created_at", precision: 6, null: false
    t.index ["uuid"], name: "index_notifications_on_uuid", unique: true
  end

  create_table "providers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.string "stripe_account_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "purchases", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "table_object_id"
    t.string "payment_intent_id"
    t.string "provider_name"
    t.string "provider_image"
    t.string "product_name"
    t.string "product_image"
    t.integer "price"
    t.string "currency"
    t.boolean "completed", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "sessions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "app_id"
    t.string "secret"
    t.datetime "exp"
    t.string "device_name"
    t.string "device_type"
    t.string "device_os"
    t.datetime "created_at", precision: 6, null: false
  end

  create_table "table_object_collections", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "table_object_id"
    t.bigint "collection_id"
    t.datetime "created_at", precision: 6, null: false
  end

  create_table "table_object_properties", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "table_object_id"
    t.string "name"
    t.text "value"
  end

  create_table "table_object_user_accesses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "table_object_id"
    t.bigint "table_alias"
    t.datetime "created_at", precision: 6, null: false
  end

  create_table "table_objects", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "table_id"
    t.string "uuid"
    t.boolean "file", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["uuid"], name: "index_table_objects_on_uuid", unique: true
  end

  create_table "table_property_types", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "table_id"
    t.string "name"
    t.integer "data_type", default: 0
  end

  create_table "tables", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "app_id"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "user_activities", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "time"
    t.integer "count_daily", default: 0
    t.integer "count_monthly", default: 0
    t.integer "count_yearly", default: 0
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "email"
    t.string "first_name"
    t.string "password_digest"
    t.boolean "confirmed", default: false
    t.string "email_confirmation_token"
    t.string "password_confirmation_token"
    t.string "old_email"
    t.string "new_email"
    t.string "new_password"
    t.bigint "used_storage", default: 0
    t.datetime "last_active"
    t.string "stripe_customer_id"
    t.integer "plan", default: 0
    t.integer "subscription_status", default: 0
    t.timestamp "period_end"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "web_push_subscriptions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.string "uuid"
    t.string "endpoint"
    t.string "p256dh"
    t.string "auth"
    t.datetime "created_at", precision: 6, null: false
    t.index ["uuid"], name: "index_web_push_subscriptions_on_uuid", unique: true
  end

end
