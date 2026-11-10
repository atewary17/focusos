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

ActiveRecord::Schema[8.1].define(version: 2026_11_10_060000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "device_id"
    t.string "token_digest", null: false
    t.string "name", null: false
    t.datetime "last_used_at"
    t.datetime "expires_at"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_api_tokens_on_device_id"
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "app_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "device_id", null: false
    t.string "package_name", null: false
    t.datetime "started_at", null: false
    t.datetime "ended_at", null: false
    t.integer "duration_seconds", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id", "package_name", "started_at"], name: "idx_on_device_id_package_name_started_at_413d760eae", unique: true
    t.index ["user_id", "started_at"], name: "index_app_sessions_on_user_id_and_started_at"
  end

  create_table "app_usage_days", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "device_id", null: false
    t.date "date", null: false
    t.string "package_name", null: false
    t.string "app_label"
    t.integer "foreground_seconds", default: 0, null: false
    t.integer "launches", default: 0, null: false
    t.datetime "first_used_at"
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id", "package_name", "date"], name: "index_app_usage_days_on_device_id_and_package_name_and_date", unique: true
    t.index ["user_id", "date"], name: "index_app_usage_days_on_user_id_and_date"
    t.index ["user_id"], name: "index_app_usage_days_on_user_id"
  end

  create_table "check_ins", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "device_id", null: false
    t.datetime "asked_at", null: false
    t.string "answer", null: false
    t.datetime "answered_at"
    t.string "source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id", "asked_at"], name: "index_check_ins_on_device_id_and_asked_at", unique: true
    t.index ["user_id", "asked_at"], name: "index_check_ins_on_user_id_and_asked_at"
  end

  create_table "devices", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "kind", null: false
    t.string "installation_id", null: false
    t.string "name", null: false
    t.string "manufacturer"
    t.string "model"
    t.string "os_version"
    t.string "app_version"
    t.datetime "last_sync_at"
    t.jsonb "last_sync_summary", default: {}, null: false
    t.jsonb "permissions", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "installation_id"], name: "index_devices_on_user_id_and_installation_id", unique: true
    t.index ["user_id"], name: "index_devices_on_user_id"
  end

  create_table "health_samples", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "device_id", null: false
    t.string "kind", null: false
    t.datetime "recorded_at", null: false
    t.datetime "end_at"
    t.decimal "value", precision: 12, scale: 3, null: false
    t.string "unit", null: false
    t.string "source_package", null: false
    t.string "external_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_health_samples_on_device_id"
    t.index ["user_id", "kind", "recorded_at", "source_package"], name: "index_health_samples_uniqueness", unique: true
  end

  create_table "screen_events", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "device_id", null: false
    t.string "kind", null: false
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id", "kind", "occurred_at"], name: "index_screen_events_on_device_id_and_kind_and_occurred_at", unique: true
    t.index ["user_id", "occurred_at"], name: "index_screen_events_on_user_id_and_occurred_at"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sleep_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "device_id", null: false
    t.datetime "started_at", null: false
    t.datetime "ended_at", null: false
    t.string "source_package", null: false
    t.string "external_id"
    t.jsonb "stages", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_sleep_sessions_on_device_id"
    t.index ["user_id", "source_package", "started_at"], name: "index_sleep_sessions_uniqueness", unique: true
  end

  create_table "solid_queue_batch_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "batch_id", null: false
    t.datetime "created_at", null: false
    t.index ["batch_id"], name: "index_solid_queue_batch_executions_on_batch_id"
    t.index ["job_id"], name: "index_solid_queue_batch_executions_on_job_id", unique: true
  end

  create_table "solid_queue_batches", force: :cascade do |t|
    t.string "active_job_batch_id"
    t.string "description"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_failure"
    t.text "metadata"
    t.integer "total_jobs", default: 0, null: false
    t.integer "completed_jobs", default: 0, null: false
    t.integer "failed_jobs", default: 0, null: false
    t.datetime "enqueued_at"
    t.datetime "finished_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_batch_id"], name: "index_solid_queue_batches_on_active_job_batch_id", unique: true
    t.index ["finished_at"], name: "index_solid_queue_batches_on_finished_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "batch_id"
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["batch_id"], name: "index_solid_queue_jobs_on_batch_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "subjects", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "color", default: "#0f766e", null: false
    t.integer "weekly_target_minutes"
    t.integer "position", default: 0, null: false
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "position"], name: "index_subjects_on_user_id_and_position"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "topic_id"
    t.bigint "subject_id"
    t.string "title", null: false
    t.text "notes"
    t.integer "position", default: 0, null: false
    t.integer "priority"
    t.date "due_on"
    t.integer "estimate_minutes"
    t.string "energy"
    t.string "status", default: "pending", null: false
    t.datetime "completed_at"
    t.bigint "carried_from_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "scheduled_on"
    t.datetime "starts_at"
    t.jsonb "subtasks", default: [], null: false
    t.index ["subject_id"], name: "index_tasks_on_subject_id"
    t.index ["topic_id"], name: "index_tasks_on_topic_id"
    t.index ["user_id", "scheduled_on", "position"], name: "index_tasks_on_user_id_and_scheduled_on_and_position"
  end

  create_table "topics", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "subject_id", null: false
    t.string "name", null: false
    t.string "status", default: "not_started", null: false
    t.integer "estimated_minutes"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subject_id", "position"], name: "index_topics_on_subject_id_and_position"
    t.index ["user_id"], name: "index_topics_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", default: "", null: false
    t.string "time_zone", default: "Asia/Kolkata", null: false
    t.datetime "consented_at"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "api_tokens", "devices"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "app_sessions", "devices"
  add_foreign_key "app_sessions", "users"
  add_foreign_key "app_usage_days", "devices"
  add_foreign_key "app_usage_days", "users"
  add_foreign_key "check_ins", "devices"
  add_foreign_key "check_ins", "users"
  add_foreign_key "devices", "users"
  add_foreign_key "health_samples", "devices"
  add_foreign_key "health_samples", "users"
  add_foreign_key "screen_events", "devices"
  add_foreign_key "screen_events", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "sleep_sessions", "devices"
  add_foreign_key "sleep_sessions", "users"
  add_foreign_key "solid_queue_batch_executions", "solid_queue_batches", column: "batch_id", on_delete: :cascade
  add_foreign_key "solid_queue_batch_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "subjects", "users"
  add_foreign_key "tasks", "subjects"
  add_foreign_key "tasks", "tasks", column: "carried_from_id"
  add_foreign_key "tasks", "topics"
  add_foreign_key "tasks", "users"
  add_foreign_key "topics", "subjects"
  add_foreign_key "topics", "users"
end
