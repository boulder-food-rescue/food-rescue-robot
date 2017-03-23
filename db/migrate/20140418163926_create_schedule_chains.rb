class CreateScheduleChains < ActiveRecord::Migration
  def change
    create_table :schedule_chains do |c|
      c.time :detailed_start_time
      c.time :detailed_stop_time
      c.date :detailed_date
      c.references :transport_type
      c.boolean :backup
      c.boolean :temporary
      c.boolean :irregular
      c.integer :difficulty_rating
      c.integer :hilliness
      c.references :scale_type
      c.references :region
      c.text :frequency
      c.integer :day_of_week
      c.integer :expected_weight
      c.text :public_notes
      c.text :admin_notes
    end
    create_table :log_recipients do |lr|
      lr.belongs_to :log
      lr.belongs_to :recipient
    end
    change_table :schedules do |s|
      s.references :schedule_chain
      s.references :location
      s.integer :position
    end
    change_table :schedule_volunteers do |sv|
      sv.references :schedule_chain
    end
    change_table :logs do |l|
      l.references :schedule_chain
    end

    old_schedules = Schedule.all.collect{ |s| s.id }
    n = 0
    old_schedules.each{ |sid|
      original = Schedule.find(sid)
      puts "Converting #{sid}: #{n}/#{old_schedules.length}"
      sc = ScheduleChain.create(irregular: original.irregular, backup: original.backup,	frequency: original.frequency,
                                 detailed_start_time: original.detailed_start_time, detailed_stop_time: original.detailed_stop_time,
                                 detailed_date: original.detailed_date, hilliness: original.hilliness,
                                 difficulty_rating: original.difficulty_rating,
                                 region_id: original.region_id, day_of_week: original.day_of_week, expected_weight: original.expected_weight,
                                 public_notes: original.public_notes, admin_notes: original.admin_notes, transport_type_id: original.transport_type_id)
      Schedule.create(food_type_ids: original.food_type_ids, location_id: original.donor_id, schedule_chain_id: sc.id, position: 0)
      Schedule.create(food_type_ids: original.food_type_ids, location_id: original.recipient_id, schedule_chain_id: sc.id, position: 1)
      original.schedule_volunteers.each{ |sv|
        sv.schedule_chain = sc
        sv.schedule = nil
        sv.save
      }
      original.logs.each{ |l|
        l.schedule_chain = sc
        l.schedule = nil
        l.save
      }
      original.delete
      n += 1
    }
    change_table :schedules do |s|
      s.remove :detailed_start_time
      s.remove :detailed_stop_time
      s.remove :detailed_date
      s.remove :backup
      s.remove :temporary
      s.remove :irregular
      s.remove :difficulty_rating
      s.remove :hilliness
      s.remove :day_of_week
      s.remove :frequency
      s.remove :expected_weight
      s.remove :public_notes
      s.remove :admin_notes
      s.remove :transport_type_id
      s.remove :region_id
      s.remove :donor_id
      s.remove :recipient_id
    end
    change_table :schedule_volunteers do |sv|
      sv.remove :schedule_id
    end
    # this is slow so do this last
    n = 0
    ntotal = Log.count
    Log.all.each do |log|
      puts "Converting #{log.id}: #{n}/#{ntotal}"
      log.recipients << log.recipient unless log.recipient.nil?
      log.save
      n += 1
    end
    change_table :logs do |l|
      l.remove :schedule_id
      l.remove :recipient_id
    end
  end

end
