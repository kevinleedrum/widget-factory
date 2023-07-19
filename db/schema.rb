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

ActiveRecord::Schema[7.0].define(version: 2023_07_19_163802) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "user_settings", force: :cascade do |t|
    t.string "user_uuid"
    t.integer "widget_id", null: false
    t.string "name"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["widget_id"], name: "index_user_settings_on_widget_id"
  end

  create_table "user_widgets", force: :cascade do |t|
    t.string "user_uuid"
    t.integer "widget_id", null: false
    t.integer "row_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "removed", default: false
    t.index ["widget_id"], name: "index_user_widgets_on_widget_id"
  end

  create_table "widget_submission_logs", force: :cascade do |t|
    t.bigint "widget_id", null: false
    t.string "status"
    t.text "notes"
    t.string "updated_by"
    t.string "logo_link_url"
    t.string "external_url"
    t.string "external_preview_url"
    t.string "external_expanded_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["widget_id"], name: "index_widget_submission_logs_on_widget_id"
  end

  create_table "widgets", force: :cascade do |t|
    t.string "component"
    t.string "partner"
    t.string "name"
    t.string "description"
    t.string "logo_link_url"
    t.string "status"
    t.datetime "activation_date"
    t.string "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_url"
    t.string "external_preview_url"
    t.string "external_expanded_url"
    t.datetime "submitted_at"
    t.string "submitted_by_uuid"
    t.text "submission_notes"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "user_settings", "widgets"
  add_foreign_key "user_widgets", "widgets"
  add_foreign_key "widget_submission_logs", "widgets"
end
