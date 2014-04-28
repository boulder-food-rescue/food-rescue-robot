class CreateScheduleChains < ActiveRecord::Migration
  def up
		create_table :schedule_chains do |c|
			c.references :schedule_volunteer
			c.references :schedule
			c.time :detailed_start_time
			c.time :detailed_stop_time
			c.date :detailed_date
			c.boolean :backup
			c.boolean :temporary
			c.boolean :irregular
			c.integer :difficulty_rating
			c.integer :hilliness
			c.references :scale_type
		end
		change_table :schedules do |s|
			s.references :schedule_chain
			s.references :location
			s.boolean :new
		end
		Schedule.all.each{ |old|
			old.new=false
		}
		Schedule.all.each{ |original|
			unless original.new?
				@sc = ScheduleChain.create(schedule_volunteer_ids: original.schedule_volunteer_ids, region_id: original.region_id, irregular: original.irregular,
																   backup: original.backup, transport_type_id: original.transport_type_id,
																   weekdays: original.weekdays, day_of_week: original.day_of_week, detailed_start_time: original.detailed_start_time,
																   detailed_stop_time: original.detailed_stop_time, detailed_date: original.detailed_date, hilliness: original.hilliness,
																   difficulty_rating: original.difficulty_rating, scale_type_id: original.scale_type_id)
				@donor = @sc.schedules.create(food_type_ids: original.food_type_ids, location_id: original.donor_id, public_notes: original.public_notes,
																		  admin_notes: original.admin_notes, expected_weight: original.expected_weight, position: 0, new: true)
				@recip = @sc.schedules.create(food_type_ids: original.food_type_ids, location_id: original.recipient_id, public_notes: original.public_notes,
																		  admin_notes: original.admin_notes, expected_weight: original.expected_weight, position: 1, new: true)
				original.delete
			end
		}
		change_table :schedules do |s|
			s.remove :new
			#s.remove :schedule_volunteer
			s.remove :detailed_start_time
			s.remove :detailed_stop_time
			s.remove :detailed_date
			s.remove :backup
			s.remove :temporary
			s.remove :irregular
			s.remove :difficulty_rating
			s.remove :hilliness
			#s.remove :scale_type
		end
  end

  def down
  end
end
