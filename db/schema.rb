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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130512224042) do

  create_table "assignments", :force => true do |t|
    t.integer  "volunteer_id"
    t.integer  "region_id"
    t.boolean  "admin"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "assignments", ["region_id"], :name => "index_assignments_on_region_id"
  add_index "assignments", ["volunteer_id"], :name => "index_assignments_on_volunteer_id"

  create_table "cell_carriers", :force => true do |t|
    t.string "name"
    t.string "format"
  end

  create_table "food_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "region_id"
  end

  create_table "locations", :force => true do |t|
    t.boolean  "is_donor"
    t.string   "recip_category"
    t.string   "donor_type"
    t.text     "address"
    t.string   "name"
    t.decimal  "lat"
    t.decimal  "lng"
    t.text     "contact"
    t.string   "website"
    t.text     "admin_notes"
    t.text     "public_notes"
    t.text     "hours"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.integer  "region_id"
    t.string   "twitter_handle"
    t.string   "receipt_key"
  end

  create_table "log_parts", :force => true do |t|
    t.integer  "log_id"
    t.integer  "food_type_id"
    t.boolean  "required"
    t.decimal  "weight"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.integer  "count"
    t.string   "description"
  end

  add_index "log_parts", ["food_type_id"], :name => "index_log_parts_on_food_type_id"
  add_index "log_parts", ["log_id"], :name => "index_log_parts_on_log_id"

  create_table "logs", :force => true do |t|
    t.integer  "schedule_id"
    t.date     "when"
    t.integer  "volunteer_id"
    t.integer  "orig_volunteer_id"
    t.text     "description"
    t.text     "notes"
    t.integer  "num_reminders"
    t.boolean  "flag_for_admin"
    t.string   "weighed_by"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.integer  "donor_id"
    t.integer  "recipient_id"
    t.integer  "transport_type_id"
    t.integer  "region_id"
    t.boolean  "complete",          :default => false
  end

  add_index "logs", ["schedule_id"], :name => "index_logs_on_schedule_id"
  add_index "logs", ["volunteer_id"], :name => "index_logs_on_volunteer_id"

  create_table "regions", :force => true do |t|
    t.decimal  "lat"
    t.decimal  "lng"
    t.string   "name"
    t.string   "website"
    t.text     "address"
    t.text     "notes"
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.string   "handbook_url"
    t.integer  "prior_lbs_rescued"
    t.integer  "prior_num_pickups"
    t.string   "twitter_key"
    t.string   "twitter_secret"
    t.string   "twitter_token"
    t.string   "twitter_token_secret"
    t.integer  "twitter_last_poundage"
    t.datetime "twitter_last_timestamp"
    t.string   "title"
    t.string   "tagline"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.string   "phone"
    t.string   "tax_id"
    t.text     "welcome_email_text"
    t.text     "splash_html"
    t.string   "weight_unit",            :default => "pound", :null => false
  end

  create_table "schedule_parts", :force => true do |t|
    t.integer  "schedule_id"
    t.integer  "food_type_id"
    t.boolean  "required"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "schedule_parts", ["food_type_id"], :name => "index_schedule_parts_on_food_type_id"
  add_index "schedule_parts", ["schedule_id"], :name => "index_schedule_parts_on_schedule_id"

  create_table "schedules", :force => true do |t|
    t.integer  "recipient_id"
    t.integer  "donor_id"
    t.integer  "volunteer_id"
    t.integer  "prior_volunteer_id"
    t.integer  "day_of_week"
    t.integer  "time_start"
    t.integer  "time_stop"
    t.text     "admin_notes"
    t.text     "public_notes"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.boolean  "irregular"
    t.boolean  "backup"
    t.integer  "transport_type_id"
    t.integer  "region_id"
  end

  add_index "schedules", ["volunteer_id"], :name => "index_schedules_on_volunteer_id"

  create_table "transport_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "volunteers", :force => true do |t|
    t.string   "email"
    t.string   "name"
    t.string   "phone"
    t.string   "preferred_contact"
    t.boolean  "has_car"
    t.text     "admin_notes"
    t.text     "pickup_prefs"
    t.date     "gone_until"
    t.boolean  "is_disabled"
    t.boolean  "on_email_list"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "encrypted_password",     :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.boolean  "admin",                  :default => false
    t.integer  "transport_type_id"
    t.integer  "cell_carrier_id"
    t.boolean  "sms_too",                :default => false
    t.boolean  "pre_reminders_too",      :default => false
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.boolean  "get_sncs_email",         :default => false, :null => false
    t.boolean  "waiver_signed",          :default => false, :null => false
    t.datetime "waiver_signed_at"
    t.boolean  "needs_training",         :default => true
    t.boolean  "assigned",               :default => false, :null => false
    t.integer  "requested_region_id"
  end

  add_index "volunteers", ["email"], :name => "index_volunteers_on_email", :unique => true
  add_index "volunteers", ["reset_password_token"], :name => "index_volunteers_on_reset_password_token", :unique => true

end
