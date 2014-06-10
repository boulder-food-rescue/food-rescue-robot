class CreateScheduleChains < ActiveRecord::Migration
  def up
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
      c.references :schedules
			c.text :frequency
			c.integer :day_of_week
			c.integer :expected_weight
			c.text :public_notes
			c.text :admin_notes
    end
    create_table :log_donors do |ld|
      ld.belongs_to :log
      ld.belongs_to :donor
    end
    Log.all.each do |log|
      log.donors << log.donor unless log.donor.nil?
    end
		change_table :schedules do |s|
			s.references :schedule_chain
			s.references :location
			s.boolean :new
			s.integer :position
    end
		change_table :schedule_volunteers do |sv|
			sv.references :schedule_chain
		end
		Schedule.all.each{ |old|
			old.new=false
		}
		Schedule.all.each{ |original|
			unless original.new?
				sc = ScheduleChain.create(schedule_volunteers: original.schedule_volunteers, irregular: original.irregular,
																   backup: original.backup,	frequency: original.frequency,
                                   detailed_start_time: original.detailed_start_time, detailed_stop_time: original.detailed_stop_time,
                                   detailed_date: original.detailed_date, hilliness: original.hilliness,
																   difficulty_rating: original.difficulty_rating,
                                   region_id: original.region_id, day_of_week: original.day_of_week, expected_weight: original.expected_weight,
                                   public_notes: original.public_notes, admin_notes: original.admin_notes, transport_type_id: original.transport_type_id)
				donor = sc.schedules.create(food_type_ids: original.food_type_ids, location_id: original.donor_id, new: true)
				recip = sc.schedules.create(food_type_ids: original.food_type_ids, location_id: original.recipient_id, new: true)
        sc.schedules << donor
        sc.schedules << recip
        donor.schedule_chain_id = sc.id
        recip.schedule_chain_id = sc.id
				ScheduleVolunteer.where(["schedule_id = ?",original.id]).each { |sv|
					sv.schedule_chain_id=sc.id
					sv.save
				}
				original.delete
			end
		}
		change_table :schedules do |s|
			s.remove :new
			s.remove :detailed_start_time
			s.remove :detailed_stop_time
			s.remove :detailed_date
			s.remove :backup
			s.remove :temporary
      s.remove :location_id
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
  end

  def down
		#doesn't reverse changes to schedules, but undoes table changes
		change_table :schedules do |s|
			s.time :detailed_start_time
			s.time :detailed_stop_time
			s.date :detailed_date
			s.references :transport_type
			s.boolean :backup
			s.boolean :temporary
			s.boolean :irregular
			s.integer :difficulty_rating
			s.integer :hilliness
			s.references :scale_type
			s.references :region
			s.text :frequency
			s.integer :day_of_week
			s.integer :expected_weight
			s.text :public_notes
			s.text :admin_notes
			s.references :donor
			s.references :recipient
			s.remove :schedule_chain_id
		end
		#change_table :logs do |l|
		#	l.integer :donor_id
		#	l.remove :donor_ids
		#end
		drop_table :schedule_chains
		drop_table :log_donors
		change_table :schedule_volunteers do |sv|
			sv.remove :schedule_chain_id
			sv.integer :schedule_id
		end
  end
end
