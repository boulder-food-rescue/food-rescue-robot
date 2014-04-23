class CreateScheduleChains < ActiveRecord::Migration
  def up
		create_table :schedule_chains do |c|
			c.references :volunteer
			c.references :schedule
			c.time :start_time
			c.time :stop_time
			c.date :chain_date
		end
		change_table :schedules do |s|
			s.references :schedule_chain
			s.references :location
		end
		Schedule.all.each{ |donor|
			sc = ScheduleChain.new
			recip = donor
			recip.schedule_chain_id = sc.id
			donor.schedule_chain_id = sc.id
			recip.location_id = donor.recipient_id
			donor.location_id = donor.donor_id
			sc.save
			recip.save
			donor.save
		}
  end

  def down
  end
end
