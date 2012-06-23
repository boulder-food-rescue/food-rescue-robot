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

ActiveRecord::Schema.define(:version => 20120622233237) do

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
  end

  create_table "logs", :force => true do |t|
    t.integer  "schedule_id"
    t.date     "when"
    t.integer  "volunteer_id"
    t.integer  "orig_volunteer_id"
    t.decimal  "weight"
    t.text     "description"
    t.string   "transport"
    t.text     "notes"
    t.integer  "num_reminders"
    t.boolean  "flag_for_admin"
    t.string   "weighed_by"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.integer  "donor_id"
    t.integer  "recipient_id"
  end

  add_index "logs", ["schedule_id"], :name => "index_logs_on_schedule_id"
  add_index "logs", ["volunteer_id"], :name => "index_logs_on_volunteer_id"

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
    t.boolean  "needs_training"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.string   "transport"
  end

  add_index "schedules", ["volunteer_id"], :name => "index_schedules_on_volunteer_id"

  create_table "volunteers", :force => true do |t|
    t.string   "email"
    t.string   "name"
    t.string   "phone"
    t.string   "preferred_contact"
    t.string   "transport"
    t.boolean  "has_car"
    t.text     "admin_notes"
    t.text     "pickup_prefs"
    t.date     "gone_until"
    t.boolean  "is_disabled"
    t.boolean  "on_email_list"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

end
