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
			c.text :frequency
			c.integer :day_of_week
			c.integer :expected_weight
			c.text :public_notes
			c.text :admin_notes
		end
		change_table :regions do |r|
			r.references :location
		end
		Region.all.each { |reg|
			Location.where(["region_id = ?",reg.id]).each do |loc|
				reg.location_ids.add(loc.id)
			end
		}
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
				@sc = ScheduleChain.create(schedule_volunteer_ids: original.schedule_volunteer_ids, region_id: original.region_id, irregular: original.irregular,
																   backup: original.backup, transport_type_id: original.transport_type_id,	frequency: original.frequency,
																   weekdays: original.weekdays, day_of_week: original.day_of_week, detailed_start_time: original.detailed_start_time,
																   detailed_stop_time: original.detailed_stop_time, detailed_date: original.detailed_date, hilliness: original.hilliness,
																   difficulty_rating: original.difficulty_rating, scale_type_id: original.scale_type_id, region_id: original.region,
																	 day_of_week: original.day_of_week, expected_weight: original.expected_weight, public_notes: original.public_notes,
																	 admin_notes: original.admin_notes, transport_type_id: original.transport_type_id)
				@donor = @sc.schedules.create(food_type_ids: original.food_type_ids, location_id: original.donor_id, new: true)
				@recip = @sc.schedules.create(food_type_ids: original.food_type_ids, location_id: original.recipient_id, new: true)
				@donor.update_attribute :position_position, :first
				@recip.update_attribute :position_position, :last
				ScheduleVolunteer.all.where(["schedule_id = ?",original.id]).each { |sv|
					sv.schedule_chain_id=@sc.id
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
			s.remove :irregular
			s.remove :difficulty_rating
			s.remove :hilliness
			s.remove :day_of_week
			s.remove :frequency
			s.remove :expected_weight
			s.remove :public_notes
			s.remove :admin_notes
			s.remove :transport_type_id
		end
		change_table :schedule_volunteers do |sv|
			sv.remove :schedule_id
		end
  end

  def down
  end
end
