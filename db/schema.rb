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

ActiveRecord::Schema[7.2].define(version: 2026_04_15_170000) do
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

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "actor_id"
    t.string "action", null: false
    t.string "auditable_type"
    t.bigint "auditable_id"
    t.jsonb "context_data", default: {}, null: false
    t.jsonb "change_set", default: {}, null: false
    t.string "ip_address"
    t.string "request_id"
    t.text "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["actor_id"], name: "index_audit_logs_on_actor_id"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
  end

  create_table "blocks", force: :cascade do |t|
    t.string "identification"
    t.integer "floors_count"
    t.integer "apartments_per_floor"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "ticket_id", null: false
    t.bigint "user_id", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ticket_id"], name: "index_comments_on_ticket_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "actor_id"
    t.bigint "ticket_id"
    t.string "kind", null: false
    t.string "title", null: false
    t.text "body", null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["kind"], name: "index_notifications_on_kind"
    t.index ["ticket_id"], name: "index_notifications_on_ticket_id"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "ticket_statuses", force: :cascade do |t|
    t.string "name"
    t.boolean "is_default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_final", default: false, null: false
    t.index ["is_default"], name: "index_ticket_statuses_on_is_default_true", unique: true, where: "is_default"
  end

  create_table "ticket_types", force: :cascade do |t|
    t.string "title"
    t.integer "sla_hours"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tickets", force: :cascade do |t|
    t.bigint "unit_id", null: false
    t.bigint "user_id", null: false
    t.bigint "ticket_type_id", null: false
    t.bigint "ticket_status_id", null: false
    t.text "description"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "sla_started_at"
    t.datetime "sla_due_at"
    t.datetime "sla_breached_at"
    t.integer "sla_cycle", default: 1, null: false
    t.index ["sla_breached_at"], name: "index_tickets_on_sla_breached_at"
    t.index ["sla_due_at"], name: "index_tickets_on_sla_due_at"
    t.index ["ticket_status_id", "sla_due_at"], name: "index_tickets_on_ticket_status_id_and_sla_due_at"
    t.index ["ticket_status_id"], name: "index_tickets_on_ticket_status_id"
    t.index ["ticket_type_id"], name: "index_tickets_on_ticket_type_id"
    t.index ["unit_id"], name: "index_tickets_on_unit_id"
    t.index ["user_id"], name: "index_tickets_on_user_id"
  end

  create_table "units", force: :cascade do |t|
    t.bigint "block_id", null: false
    t.string "identifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["block_id"], name: "index_units_on_block_id"
  end

  create_table "user_ticket_types", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "ticket_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ticket_type_id"], name: "index_user_ticket_types_on_ticket_type_id"
    t.index ["user_id"], name: "index_user_ticket_types_on_user_id"
  end

  create_table "user_units", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "unit_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["unit_id"], name: "index_user_units_on_unit_id"
    t.index ["user_id", "unit_id"], name: "index_user_units_on_user_id_and_unit_id", unique: true
    t.index ["user_id"], name: "index_user_units_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.integer "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "audit_logs", "users", column: "actor_id"
  add_foreign_key "comments", "tickets"
  add_foreign_key "comments", "users"
  add_foreign_key "notifications", "tickets"
  add_foreign_key "notifications", "users"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "tickets", "ticket_statuses"
  add_foreign_key "tickets", "ticket_types"
  add_foreign_key "tickets", "units"
  add_foreign_key "tickets", "users"
  add_foreign_key "units", "blocks"
  add_foreign_key "user_ticket_types", "ticket_types"
  add_foreign_key "user_ticket_types", "users"
  add_foreign_key "user_units", "units"
  add_foreign_key "user_units", "users"
end
