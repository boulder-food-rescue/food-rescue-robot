#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Webapp::Application.load_tasks

task(:generate_logs => :environment) do
  Rails.logger = Logger.new(STDOUT)
  include LogsHelper
  # Generate entries for today and tomorrow (shouldn't duplicate...)
  generate_log_entries(Date.today)
  generate_log_entries(Date.today+1)
  generate_log_entries(Date.today+2)
end

task(:send_reminders => :environment) do
  Rails.logger = Logger.new(STDOUT)
  include LogsHelper
  send_reminder_emails(1) # email day-after-pickup
end

task(:send_weekly_summary => :environment) do
  Rails.logger = Logger.new(STDOUT)
  include LogsHelper
  send_weekly_pickup_summary # email day-after-pickup
end

#  create_table "log_parts", :force => true do |t|
#    t.integer  "log_id"
#    t.integer  "food_type_id"
#    t.boolean  "required"
#    t.decimal  "weight"
#    t.datetime "created_at",   :null => false
#    t.datetime "updated_at",   :null => false
#    t.integer  "count"
#    t.text     "description"
#  end

#  add_index "log_parts", ["food_type_id"], :name => "index_log_parts_on_food_type_id"
#  add_index "log_parts", ["log_id"], :name => "index_log_parts_on_log_id"

#  create_table "logs", :force => true do |t|
#    t.integer  "schedule_id"
#    t.date     "when"
#    t.integer  "volunteer_id"
#    t.integer  "orig_volunteer_id"
#    t.text     "notes"
#    t.integer  "num_reminders"
#    t.boolean  "flag_for_admin"
#    t.string   "weighed_by"
#    t.datetime "created_at",                           :null => false
#    t.datetime "updated_at",                           :null => false
#    t.integer  "donor_id"
#    t.integer  "recipient_id"
#    t.integer  "transport_type_id"
#    t.integer  "region_id"
#    t.boolean  "complete",          :default => false
#  end

task(:export_log_data => :environment) do
  CSV.open("data#{Time.zone.now.strftime("%Y%m%d")}.csv","wb") do |csv|
    cols = ["when","volunteer","weight","food_type","weighed_by","donor","recipient","num reminders","transport_type","complete","description"]
    csv << cols
    Log.joins(:log_parts).select('"when",volunteer_id,weight,food_type_id,weighed_by,donor_id,recipient_id,complete,transport_type_id,num_reminders,description').where("region_id=1").each{ |l|
      csv << [l.when,l.volunteer.nil? ? nil : l.volunteer.name,l.weight,
              l.food_type.nil? ? nil : l.food_type.name,l.weighed_by,l.donor.nil? ? nil : l.donor.name,
              l.recipient.nil? ? nil : l.recipient.name,l.num_reminders,
              l.transport_type.nil? ? nil : l.transport_type.name, l.complete,l.description]
    }
  end
end
