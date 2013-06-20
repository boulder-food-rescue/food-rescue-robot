class AddDetailedHoursToSchedule < ActiveRecord::Migration
  def change
    change_table :schedules do |t|
      t.time :detailed_start_time
      t.time :detailed_stop_time
    end
  end
end
