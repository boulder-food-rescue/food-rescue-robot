#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Webapp::Application.load_tasks

task(:export_log_data => :environment) do

  CSV.open("orgs.csv","wb") do |csv|
    csv << ["id","name","lat","lng","type"]
    Location.where("region_id = ?",1).each{ |l|
      csv << [l.id,l.name,l.lat,l.lng,l.is_donor ? "donor" : "recipient"]
    }
  end

  n = 0
  CSV.open("logs.csv","wb") do |csv|
    csv << ["id","date","volunteer_ids","donor_id","recipient_ids","part_ids",
            "part_food_types","part_weights","part_counts",
            "transport","scale","why_zero","schedule_id"]
    ntotal = Log.where("region_id = ? AND complete",1).count
    Log.where("region_id = ? AND complete",1).each{ |l|
      lp = LogPart.select("log_parts.id,food_types.name,weight,count").where("log_id = ?",l.id).
        joins("LEFT JOIN food_types ON log_parts.food_type_id=food_types.id")
      tt = l.transport_type.nil? ? "" : l.transport_type.name
      st = l.scale_type.nil? ? "" : l.scale_type.name
      csv << [l.id,l.when,l.volunteers.collect{ |v| v.id }.join(":"),l.donor_id,l.recipients.collect{ |r| r.id }.join(":"),
              lp.collect{ |p| p.id }.join(":"),lp.collect{ |p| p.name }.join(":"),lp.collect{ |p| p.weight }.join(":"),
              lp.collect{ |p| p.count }.join(":"),tt,st,l.why_zero,l.schedule_chain_id]

      n += 1
      if n % 100 == 0
        puts (100.0*(n/ntotal.to_f)).round.to_s + "%"
      end
    }
  end

end
