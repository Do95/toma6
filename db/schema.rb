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

ActiveRecord::Schema[8.0].define(version: 2026_10_27_000003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "about_values", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.integer "position", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.datetime "deleted_at"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.bigint "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug", null: false
    t.index ["created_by_id"], name: "index_about_values_on_created_by_id"
    t.index ["deleted_at"], name: "index_about_values_on_deleted_at"
    t.index ["deleted_by_id"], name: "index_about_values_on_deleted_by_id"
    t.index ["slug"], name: "index_about_values_on_slug", unique: true
    t.index ["updated_by_id"], name: "index_about_values_on_updated_by_id"
  end

  create_table "activity_logs", force: :cascade do |t|
    t.bigint "user_id"
    t.string "user_name"
    t.string "action", null: false
    t.string "subject_type"
    t.bigint "subject_id"
    t.string "subject_label"
    t.jsonb "changeset", default: {}, null: false
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.string "slug", null: false
    t.index ["action"], name: "index_activity_logs_on_action"
    t.index ["created_at"], name: "index_activity_logs_on_created_at"
    t.index ["slug"], name: "index_activity_logs_on_slug", unique: true
    t.index ["subject_type", "subject_id"], name: "index_activity_logs_on_subject_type_and_subject_id"
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
  end

  create_table "albums", force: :cascade do |t|
    t.bigint "project_id"
    t.string "title", null: false
    t.string "slug", null: false
    t.text "description"
    t.string "cover"
    t.boolean "show_in_gallery", default: true, null: false
    t.integer "position", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.datetime "deleted_at"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.bigint "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "cover_media_item_id"
    t.index ["cover_media_item_id"], name: "index_albums_on_cover_media_item_id"
    t.index ["created_by_id"], name: "index_albums_on_created_by_id"
    t.index ["deleted_at"], name: "index_albums_on_deleted_at"
    t.index ["deleted_by_id"], name: "index_albums_on_deleted_by_id"
    t.index ["project_id"], name: "index_albums_on_project_id"
    t.index ["slug"], name: "index_albums_on_slug"
    t.index ["updated_by_id"], name: "index_albums_on_updated_by_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "position", default: 0, null: false
    t.datetime "deleted_at"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.bigint "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_categories_on_created_by_id"
    t.index ["deleted_at"], name: "index_categories_on_deleted_at"
    t.index ["deleted_by_id"], name: "index_categories_on_deleted_by_id"
    t.index ["slug"], name: "index_categories_on_slug"
    t.index ["updated_by_id"], name: "index_categories_on_updated_by_id"
  end

  create_table "email_logs", force: :cascade do |t|
    t.string "mailer", null: false
    t.string "action", null: false
    t.string "template_key"
    t.jsonb "params", default: {}, null: false
    t.string "to"
    t.string "subject"
    t.string "status", default: "queued", null: false
    t.integer "attempts", default: 0, null: false
    t.text "error_message"
    t.text "body_html"
    t.string "record_type"
    t.bigint "record_id"
    t.bigint "triggered_by_id"
    t.datetime "sent_at"
    t.datetime "last_attempt_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug", null: false
    t.index ["created_at"], name: "index_email_logs_on_created_at"
    t.index ["record_type", "record_id"], name: "index_email_logs_on_record"
    t.index ["slug"], name: "index_email_logs_on_slug", unique: true
    t.index ["status"], name: "index_email_logs_on_status"
    t.index ["triggered_by_id"], name: "index_email_logs_on_triggered_by_id"
  end

  create_table "email_templates", force: :cascade do |t|
    t.string "key", null: false
    t.string "name", null: false
    t.string "audience", default: "client", null: false
    t.string "subject", null: false
    t.string "heading"
    t.text "body", null: false
    t.string "button_label"
    t.string "recipients"
    t.boolean "enabled", default: true, null: false
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "hero_image"
    t.string "hero_asset"
    t.bigint "hero_image_media_item_id"
    t.index ["created_by_id"], name: "index_email_templates_on_created_by_id"
    t.index ["hero_image_media_item_id"], name: "index_email_templates_on_hero_image_media_item_id"
    t.index ["key"], name: "index_email_templates_on_key", unique: true
    t.index ["updated_by_id"], name: "index_email_templates_on_updated_by_id"
  end

  create_table "faqs", force: :cascade do |t|
    t.string "question", null: false
    t.text "answer", null: false
    t.integer "position", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.datetime "deleted_at"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.bigint "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug", null: false
    t.index ["created_by_id"], name: "index_faqs_on_created_by_id"
    t.index ["deleted_at"], name: "index_faqs_on_deleted_at"
    t.index ["deleted_by_id"], name: "index_faqs_on_deleted_by_id"
    t.index ["slug"], name: "index_faqs_on_slug", unique: true
    t.index ["updated_by_id"], name: "index_faqs_on_updated_by_id"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
    t.datetime "jobs_finished_at"
    t.index ["created_at", "id"], name: "index_good_job_batches_on_created_at_and_id", order: :desc
    t.index ["finished_at"], name: "index_good_job_batches_on_finished_at", where: "(finished_at IS NOT NULL)"
  end

  create_table "good_job_concurrency_claims", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "job_id", null: false
    t.uuid "locked_by_id"
    t.integer "state", limit: 2, null: false
    t.text "key", null: false
    t.index ["job_id"], name: "index_good_job_concurrency_claims_on_job_id"
    t.index ["key", "job_id"], name: "index_good_job_concurrency_claims_on_key_and_job_id", unique: true
    t.index ["key", "state", "created_at"], name: "index_good_job_concurrency_claims_for_promotion"
    t.index ["locked_by_id"], name: "index_good_job_concurrency_claims_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.text "error"
    t.integer "error_event", limit: 2
    t.text "error_backtrace", array: true
    t.uuid "process_id"
    t.interval "duration"
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
    t.index ["scheduled_at"], name: "index_good_job_executions_on_scheduled_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
    t.integer "lock_type", limit: 2
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.text "labels", array: true
    t.uuid "locked_by_id"
    t.datetime "locked_at"
    t.integer "lock_type", limit: 2
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id_unfinished", where: "((batch_callback_id IS NOT NULL) AND (finished_at IS NULL))"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id_unfinished", where: "((batch_id IS NOT NULL) AND (finished_at IS NULL))"
    t.index ["concurrency_key", "created_at"], name: "index_good_jobs_on_concurrency_key_and_created_at"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["created_at"], name: "index_good_jobs_on_created_at"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, order: { cron_at: "DESC NULLS LAST" }, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at_only", where: "(finished_at IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_on_discarded", order: :desc, where: "((finished_at IS NOT NULL) AND (error IS NOT NULL))"
    t.index ["id"], name: "index_good_jobs_on_unfinished_or_errored", where: "((finished_at IS NULL) OR (error IS NOT NULL))"
    t.index ["job_class", "finished_at"], name: "index_good_jobs_on_discarded_job_class", where: "((finished_at IS NOT NULL) AND (error IS NOT NULL))"
    t.index ["job_class"], name: "index_good_jobs_on_job_class"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at", "id"], name: "index_good_jobs_for_candidate_dequeue_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["priority", "scheduled_at", "id"], name: "index_good_jobs_on_priority_scheduled_at_unfinished", where: "(finished_at IS NULL)"
    t.index ["queue_name", "priority", "created_at"], name: "index_good_jobs_dequeue_by_queue", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "priority", "scheduled_at"], name: "index_good_jobs_dequeue_by_queue_scheduled_at", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at", "id"], name: "index_good_jobs_on_queue_name_priority_scheduled_at_unfinished", where: "(finished_at IS NULL)"
    t.index ["queue_name"], name: "index_good_jobs_on_queue_name"
    t.index ["scheduled_at", "queue_name"], name: "index_good_jobs_on_scheduled_at_and_queue_name"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "integrations", force: :cascade do |t|
    t.string "provider", null: false
    t.string "app_id"
    t.text "app_secret"
    t.string "graph_version", default: "v23.0", null: false
    t.text "user_access_token"
    t.datetime "user_token_expires_at"
    t.string "page_id"
    t.string "page_name"
    t.text "page_access_token"
    t.string "instagram_account_id"
    t.string "instagram_username"
    t.boolean "facebook_enabled", default: false, null: false
    t.boolean "instagram_enabled", default: false, null: false
    t.datetime "connected_at"
    t.bigint "connected_by_id"
    t.text "last_error"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["connected_by_id"], name: "index_integrations_on_connected_by_id"
    t.index ["created_by_id"], name: "index_integrations_on_created_by_id"
    t.index ["provider"], name: "index_integrations_on_provider", unique: true
    t.index ["updated_by_id"], name: "index_integrations_on_updated_by_id"
  end

  create_table "media_items", force: :cascade do |t|
    t.bigint "category_id"
    t.string "kind", default: "photo", null: false
    t.string "image"
    t.string "video"
    t.string "title"
    t.text "description"
    t.integer "width"
    t.integer "height"
    t.string "duration"
    t.boolean "show_in_gallery", default: true, null: false
    t.boolean "featured", default: false, null: false
    t.integer "position", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.datetime "deleted_at"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.bigint "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "checksum"
    t.string "slug", null: false
    t.index ["category_id"], name: "index_media_items_on_category_id"
    t.index ["checksum"], name: "index_media_items_on_checksum"
    t.index ["created_by_id"], name: "index_media_items_on_created_by_id"
    t.index ["deleted_at"], name: "index_media_items_on_deleted_at"
    t.index ["deleted_by_id"], name: "index_media_items_on_deleted_by_id"
    t.index ["show_in_gallery", "published"], name: "index_media_items_on_show_in_gallery_and_published"
    t.index ["slug"], name: "index_media_items_on_slug", unique: true
    t.index ["updated_by_id"], name: "index_media_items_on_updated_by_id"
  end

  create_table "media_placements", force: :cascade do |t|
    t.bigint "media_item_id", null: false
    t.bigint "album_id"
    t.bigint "project_id"
    t.integer "position", default: 0, null: false
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug", null: false
    t.index ["album_id"], name: "index_media_placements_on_album_id"
    t.index ["created_by_id"], name: "index_media_placements_on_created_by_id"
    t.index ["media_item_id", "album_id"], name: "index_placements_unique_album", unique: true, where: "(album_id IS NOT NULL)"
    t.index ["media_item_id", "project_id"], name: "index_placements_unique_project", unique: true, where: "(album_id IS NULL)"
    t.index ["media_item_id"], name: "index_media_placements_on_media_item_id"
    t.index ["project_id"], name: "index_media_placements_on_project_id"
    t.index ["slug"], name: "index_media_placements_on_slug", unique: true
    t.index ["updated_by_id"], name: "index_media_placements_on_updated_by_id"
    t.check_constraint "(album_id IS NOT NULL) <> (project_id IS NOT NULL)", name: "placement_one_gallery"
  end

  create_table "plans", force: :cascade do |t|
    t.string "title", null: false
    t.text "summary"
    t.text "features"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.string "price_unit"
    t.string "badge"
    t.boolean "highlighted", default: false, null: false
    t.integer "position", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.datetime "deleted_at"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.bigint "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug", null: false
    t.index ["created_by_id"], name: "index_plans_on_created_by_id"
    t.index ["deleted_at"], name: "index_plans_on_deleted_at"
    t.index ["deleted_by_id"], name: "index_plans_on_deleted_by_id"
    t.index ["slug"], name: "index_plans_on_slug", unique: true
    t.index ["updated_by_id"], name: "index_plans_on_updated_by_id"
  end

  create_table "plans_services", id: false, force: :cascade do |t|
    t.bigint "plan_id", null: false
    t.bigint "service_id", null: false
    t.index ["plan_id", "service_id"], name: "index_plans_services_on_plan_id_and_service_id", unique: true
  end

  create_table "process_steps", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.integer "position", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.datetime "deleted_at"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.bigint "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug", null: false
    t.index ["created_by_id"], name: "index_process_steps_on_created_by_id"
    t.index ["deleted_at"], name: "index_process_steps_on_deleted_at"
    t.index ["deleted_by_id"], name: "index_process_steps_on_deleted_by_id"
    t.index ["slug"], name: "index_process_steps_on_slug", unique: true
    t.index ["updated_by_id"], name: "index_process_steps_on_updated_by_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.string "category_label"
    t.string "client_name"
    t.string "location"
    t.date "event_date"
    t.text "summary"
    t.text "body"
    t.string "cover"
    t.string "video"
    t.string "video_link"
    t.boolean "featured", default: true, null: false
    t.integer "position", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.datetime "deleted_at"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.bigint "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_projects_on_created_by_id"
    t.index ["deleted_at"], name: "index_projects_on_deleted_at"
    t.index ["deleted_by_id"], name: "index_projects_on_deleted_by_id"
    t.index ["slug"], name: "index_projects_on_slug"
    t.index ["updated_by_id"], name: "index_projects_on_updated_by_id"
  end

  create_table "projects_services", id: false, force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "service_id", null: false
    t.index ["project_id", "service_id"], name: "index_projects_services_on_project_id_and_service_id", unique: true
    t.index ["project_id"], name: "index_projects_services_on_project_id"
    t.index ["service_id"], name: "index_projects_services_on_service_id"
  end

  create_table "quote_items", force: :cascade do |t|
    t.bigint "quote_id", null: false
    t.bigint "service_id"
    t.string "description", null: false
    t.text "details"
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0", null: false
    t.decimal "unit_price", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "total", precision: 12, scale: 2, default: "0.0", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quote_id"], name: "index_quote_items_on_quote_id"
    t.index ["service_id"], name: "index_quote_items_on_service_id"
  end

  create_table "quote_requests", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone"
    t.string "company"
    t.date "event_date"
    t.string "location"
    t.text "message"
    t.jsonb "selections", default: [], null: false
    t.decimal "subtotal", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "discount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "estimated_total", precision: 12, scale: 2, default: "0.0", null: false
    t.string "status", default: "new", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "deleted_at"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.bigint "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "number"
    t.bigint "plan_id"
    t.index ["created_by_id"], name: "index_quote_requests_on_created_by_id"
    t.index ["deleted_at"], name: "index_quote_requests_on_deleted_at"
    t.index ["deleted_by_id"], name: "index_quote_requests_on_deleted_by_id"
    t.index ["number"], name: "index_quote_requests_on_number", unique: true
    t.index ["plan_id"], name: "index_quote_requests_on_plan_id"
    t.index ["status"], name: "index_quote_requests_on_status"
    t.index ["updated_by_id"], name: "index_quote_requests_on_updated_by_id"
  end

  create_table "quotes", force: :cascade do |t|
    t.string "number", null: false
    t.string "token", null: false
    t.string "status", default: "draft", null: false
    t.string "title"
    t.string "client_name", null: false
    t.string "client_company"
    t.string "client_email"
    t.string "client_phone"
    t.string "client_tax_id"
    t.date "event_date"
    t.string "event_location"
    t.date "issued_on", null: false
    t.date "valid_until"
    t.string "currency_symbol", default: "$", null: false
    t.string "discount_type", default: "percent", null: false
    t.decimal "discount_value", precision: 12, scale: 2, default: "0.0", null: false
    t.string "tax_name", default: "IVA", null: false
    t.decimal "tax_rate", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "subtotal", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "discount_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "tax_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "total", precision: 12, scale: 2, default: "0.0", null: false
    t.text "notes"
    t.text "terms"
    t.text "payment_info"
    t.bigint "quote_request_id"
    t.datetime "sent_at"
    t.datetime "accepted_at"
    t.datetime "rejected_at"
    t.datetime "deleted_at"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.bigint "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_quotes_on_created_by_id"
    t.index ["deleted_at"], name: "index_quotes_on_deleted_at"
    t.index ["deleted_by_id"], name: "index_quotes_on_deleted_by_id"
    t.index ["number"], name: "index_quotes_on_number", unique: true
    t.index ["quote_request_id"], name: "index_quotes_on_quote_request_id"
    t.index ["status"], name: "index_quotes_on_status"
    t.index ["token"], name: "index_quotes_on_token", unique: true
    t.index ["updated_by_id"], name: "index_quotes_on_updated_by_id"
  end

  create_table "section_blocks", force: :cascade do |t|
    t.bigint "section_id", null: false
    t.string "illustration"
    t.string "image"
    t.string "eyebrow"
    t.string "title"
    t.text "body"
    t.string "button_label"
    t.string "button_url"
    t.integer "position", default: 0, null: false
    t.datetime "deleted_at"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.bigint "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_section_blocks_on_created_by_id"
    t.index ["deleted_at"], name: "index_section_blocks_on_deleted_at"
    t.index ["deleted_by_id"], name: "index_section_blocks_on_deleted_by_id"
    t.index ["section_id"], name: "index_section_blocks_on_section_id"
    t.index ["updated_by_id"], name: "index_section_blocks_on_updated_by_id"
  end

  create_table "sections", force: :cascade do |t|
    t.string "page", default: "home", null: false
    t.bigint "project_id"
    t.string "kind", null: false
    t.string "anchor"
    t.string "eyebrow"
    t.string "title"
    t.text "lead"
    t.text "body"
    t.text "note"
    t.text "items"
    t.string "image"
    t.string "image_side", default: "right", null: false
    t.string "video"
    t.string "video_link"
    t.string "button_label"
    t.string "button_url"
    t.string "secondary_label"
    t.string "secondary_url"
    t.string "theme", default: "dark", null: false
    t.bigint "album_id"
    t.boolean "show_in_nav", default: false, null: false
    t.string "nav_label"
    t.integer "position", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.datetime "deleted_at"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.bigint "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "illustration"
    t.string "layout", default: "3", null: false
    t.string "align", default: "left", null: false
    t.string "block_style", default: "card", null: false
    t.text "embed_code"
    t.integer "embed_height", default: 450, null: false
    t.string "slug", null: false
    t.index ["album_id"], name: "index_sections_on_album_id"
    t.index ["created_by_id"], name: "index_sections_on_created_by_id"
    t.index ["deleted_at"], name: "index_sections_on_deleted_at"
    t.index ["deleted_by_id"], name: "index_sections_on_deleted_by_id"
    t.index ["page", "project_id", "position"], name: "index_sections_on_page_and_project_id_and_position"
    t.index ["project_id"], name: "index_sections_on_project_id"
    t.index ["slug"], name: "index_sections_on_slug", unique: true
    t.index ["updated_by_id"], name: "index_sections_on_updated_by_id"
  end

  create_table "service_options", force: :cascade do |t|
    t.bigint "service_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "kind", default: "addon", null: false
    t.string "group_name"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.string "unit_label"
    t.integer "min_quantity", default: 0, null: false
    t.integer "max_quantity", default: 20, null: false
    t.boolean "default_selected", default: false, null: false
    t.integer "position", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.datetime "deleted_at"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.bigint "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_service_options_on_created_by_id"
    t.index ["deleted_at"], name: "index_service_options_on_deleted_at"
    t.index ["deleted_by_id"], name: "index_service_options_on_deleted_by_id"
    t.index ["service_id"], name: "index_service_options_on_service_id"
    t.index ["updated_by_id"], name: "index_service_options_on_updated_by_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.text "summary"
    t.text "description"
    t.string "tags"
    t.string "visual_style", default: "image", null: false
    t.string "image"
    t.string "image_secondary"
    t.string "image_tertiary"
    t.boolean "quotable", default: true, null: false
    t.decimal "base_price", precision: 10, scale: 2, default: "0.0", null: false
    t.string "price_prefix", default: "Desde"
    t.string "price_unit"
    t.integer "position", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.datetime "deleted_at"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.bigint "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "image_media_item_id"
    t.bigint "image_secondary_media_item_id"
    t.bigint "image_tertiary_media_item_id"
    t.index ["created_by_id"], name: "index_services_on_created_by_id"
    t.index ["deleted_at"], name: "index_services_on_deleted_at"
    t.index ["deleted_by_id"], name: "index_services_on_deleted_by_id"
    t.index ["image_media_item_id"], name: "index_services_on_image_media_item_id"
    t.index ["image_secondary_media_item_id"], name: "index_services_on_image_secondary_media_item_id"
    t.index ["image_tertiary_media_item_id"], name: "index_services_on_image_tertiary_media_item_id"
    t.index ["slug"], name: "index_services_on_slug"
    t.index ["updated_by_id"], name: "index_services_on_updated_by_id"
  end

  create_table "short_link_clicks", force: :cascade do |t|
    t.bigint "short_link_id", null: false
    t.string "source", default: "link", null: false
    t.string "device"
    t.string "os"
    t.string "browser"
    t.string "referrer_host"
    t.string "visitor_hash"
    t.datetime "created_at", null: false
    t.index ["short_link_id", "created_at"], name: "index_short_link_clicks_on_short_link_id_and_created_at"
    t.index ["short_link_id"], name: "index_short_link_clicks_on_short_link_id"
  end

  create_table "short_links", force: :cascade do |t|
    t.string "code", null: false
    t.string "title", null: false
    t.text "destination_url", null: false
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_campaign"
    t.datetime "expires_at"
    t.boolean "active", default: true, null: false
    t.string "qr_style", default: "brand", null: false
    t.boolean "qr_logo", default: true, null: false
    t.string "qr_label"
    t.integer "clicks_count", default: 0, null: false
    t.integer "qr_clicks_count", default: 0, null: false
    t.datetime "last_clicked_at"
    t.datetime "deleted_at"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.bigint "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_short_links_on_code", unique: true
    t.index ["created_by_id"], name: "index_short_links_on_created_by_id"
    t.index ["deleted_at"], name: "index_short_links_on_deleted_at"
    t.index ["deleted_by_id"], name: "index_short_links_on_deleted_by_id"
    t.index ["updated_by_id"], name: "index_short_links_on_updated_by_id"
  end

  create_table "site_settings", force: :cascade do |t|
    t.string "site_name", default: "toma6", null: false
    t.string "legal_name"
    t.string "logo"
    t.string "wordmark"
    t.string "og_image"
    t.string "pdf_logo"
    t.string "hero_claim"
    t.text "hero_subtitle"
    t.string "hero_primary_cta"
    t.string "hero_secondary_cta"
    t.string "ticker_primary"
    t.string "ticker_secondary"
    t.text "manifesto"
    t.string "about_title"
    t.text "about_lead"
    t.text "about_body"
    t.text "about_closing"
    t.string "services_title"
    t.text "services_intro"
    t.string "work_title"
    t.text "work_intro"
    t.string "gallery_title"
    t.text "gallery_intro"
    t.string "process_title"
    t.text "process_intro"
    t.string "faq_title"
    t.text "faq_intro"
    t.string "quote_title"
    t.text "quote_intro"
    t.string "contact_title"
    t.text "contact_intro"
    t.string "contact_email"
    t.string "notification_email"
    t.string "whatsapp_number"
    t.string "phone"
    t.string "address"
    t.string "city"
    t.string "country", default: "El Salvador"
    t.string "instagram_url"
    t.string "facebook_url"
    t.string "tiktok_url"
    t.string "youtube_url"
    t.string "site_url"
    t.string "seo_title"
    t.text "seo_description"
    t.string "google_analytics_id"
    t.text "footer_text"
    t.string "currency_symbol", default: "$", null: false
    t.string "currency_code", default: "USD", null: false
    t.string "tax_name", default: "IVA", null: false
    t.decimal "tax_rate", precision: 5, scale: 2, default: "13.0", null: false
    t.boolean "estimator_shows_tax", default: false, null: false
    t.decimal "bundle_discount_percent", precision: 5, scale: 2, default: "0.0", null: false
    t.integer "bundle_min_services", default: 2, null: false
    t.text "estimator_disclaimer"
    t.string "quote_prefix", default: "COT", null: false
    t.integer "quote_validity_days", default: 15, null: false
    t.text "quote_default_notes"
    t.text "quote_default_terms"
    t.text "quote_payment_info"
    t.integer "trash_retention_days", default: 15, null: false
    t.datetime "last_trash_purge_at"
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "quote_number_year", default: true, null: false
    t.integer "quote_number_digits", default: 4, null: false
    t.integer "quote_number_start", default: 1, null: false
    t.string "request_prefix", default: "SOL", null: false
    t.boolean "estimator_shows_prices", default: true, null: false
  end

  create_table "social_posts", force: :cascade do |t|
    t.text "body"
    t.string "link"
    t.string "image"
    t.bigint "media_item_id"
    t.boolean "to_facebook", default: false, null: false
    t.boolean "to_instagram", default: false, null: false
    t.string "status", default: "draft", null: false
    t.datetime "scheduled_at"
    t.datetime "published_at"
    t.string "facebook_post_id"
    t.string "facebook_permalink"
    t.string "instagram_media_id"
    t.string "instagram_permalink"
    t.text "error_message"
    t.datetime "deleted_at"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.bigint "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug", null: false
    t.index ["created_by_id"], name: "index_social_posts_on_created_by_id"
    t.index ["deleted_at"], name: "index_social_posts_on_deleted_at"
    t.index ["deleted_by_id"], name: "index_social_posts_on_deleted_by_id"
    t.index ["media_item_id"], name: "index_social_posts_on_media_item_id"
    t.index ["slug"], name: "index_social_posts_on_slug", unique: true
    t.index ["status", "scheduled_at"], name: "index_social_posts_on_status_and_scheduled_at"
    t.index ["updated_by_id"], name: "index_social_posts_on_updated_by_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "name", null: false
    t.string "role", default: "editor", null: false
    t.string "avatar"
    t.boolean "active", default: true, null: false
    t.datetime "deleted_at"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.bigint "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "invited_at"
    t.datetime "invitation_accepted_at"
    t.bigint "invited_by_id"
    t.string "code", null: false
    t.index ["code"], name: "index_users_on_code", unique: true
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "about_values", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "about_values", "users", column: "deleted_by_id", on_delete: :nullify
  add_foreign_key "about_values", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "activity_logs", "users", on_delete: :nullify
  add_foreign_key "albums", "media_items", column: "cover_media_item_id", on_delete: :nullify
  add_foreign_key "albums", "projects", on_delete: :cascade
  add_foreign_key "albums", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "albums", "users", column: "deleted_by_id", on_delete: :nullify
  add_foreign_key "albums", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "categories", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "categories", "users", column: "deleted_by_id", on_delete: :nullify
  add_foreign_key "categories", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "email_logs", "users", column: "triggered_by_id", on_delete: :nullify
  add_foreign_key "email_templates", "media_items", column: "hero_image_media_item_id", on_delete: :nullify
  add_foreign_key "email_templates", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "email_templates", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "faqs", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "faqs", "users", column: "deleted_by_id", on_delete: :nullify
  add_foreign_key "faqs", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "integrations", "users", column: "connected_by_id", on_delete: :nullify
  add_foreign_key "integrations", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "integrations", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "media_items", "categories", on_delete: :nullify
  add_foreign_key "media_items", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "media_items", "users", column: "deleted_by_id", on_delete: :nullify
  add_foreign_key "media_items", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "media_placements", "albums", on_delete: :cascade
  add_foreign_key "media_placements", "media_items", on_delete: :cascade
  add_foreign_key "media_placements", "projects", on_delete: :cascade
  add_foreign_key "media_placements", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "media_placements", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "process_steps", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "process_steps", "users", column: "deleted_by_id", on_delete: :nullify
  add_foreign_key "process_steps", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "projects", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "projects", "users", column: "deleted_by_id", on_delete: :nullify
  add_foreign_key "projects", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "projects_services", "projects", on_delete: :cascade
  add_foreign_key "projects_services", "services", on_delete: :cascade
  add_foreign_key "quote_items", "quotes", on_delete: :cascade
  add_foreign_key "quote_items", "services", on_delete: :nullify
  add_foreign_key "quote_requests", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "quote_requests", "users", column: "deleted_by_id", on_delete: :nullify
  add_foreign_key "quote_requests", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "quotes", "quote_requests", on_delete: :nullify
  add_foreign_key "quotes", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "quotes", "users", column: "deleted_by_id", on_delete: :nullify
  add_foreign_key "quotes", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "section_blocks", "sections", on_delete: :cascade
  add_foreign_key "section_blocks", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "section_blocks", "users", column: "deleted_by_id", on_delete: :nullify
  add_foreign_key "section_blocks", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "sections", "albums", on_delete: :nullify
  add_foreign_key "sections", "projects", on_delete: :cascade
  add_foreign_key "sections", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "sections", "users", column: "deleted_by_id", on_delete: :nullify
  add_foreign_key "sections", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "service_options", "services", on_delete: :cascade
  add_foreign_key "service_options", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "service_options", "users", column: "deleted_by_id", on_delete: :nullify
  add_foreign_key "service_options", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "services", "media_items", column: "image_media_item_id", on_delete: :nullify
  add_foreign_key "services", "media_items", column: "image_secondary_media_item_id", on_delete: :nullify
  add_foreign_key "services", "media_items", column: "image_tertiary_media_item_id", on_delete: :nullify
  add_foreign_key "services", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "services", "users", column: "deleted_by_id", on_delete: :nullify
  add_foreign_key "services", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "short_link_clicks", "short_links", on_delete: :cascade
  add_foreign_key "short_links", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "short_links", "users", column: "deleted_by_id", on_delete: :nullify
  add_foreign_key "short_links", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "site_settings", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "social_posts", "media_items", on_delete: :nullify
  add_foreign_key "social_posts", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "social_posts", "users", column: "deleted_by_id", on_delete: :nullify
  add_foreign_key "social_posts", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "users", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "users", "users", column: "deleted_by_id", on_delete: :nullify
  add_foreign_key "users", "users", column: "invited_by_id", on_delete: :nullify
  add_foreign_key "users", "users", column: "updated_by_id", on_delete: :nullify
end
