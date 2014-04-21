class CreateScheduleChains < ActiveRecord::Migration
  def up
		create_table :schedule_chains do |c|
			t.references :volunteer
			t.references :schedule
		end
		Schedule.all.each{ |s|
			
		}
  end

  def down
  end
end
