#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Webapp::Application.load_tasks

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
