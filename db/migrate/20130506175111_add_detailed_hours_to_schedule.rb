class AddDetailedHoursToSchedule < ActiveRecord::Migration
  def change
    change_table :schedules do |t|
      t.time :detailed_start_time
      t.time :detailed_stop_time
    end
    Schedule.all.each{ |s|
      s.detailed_start_time = Time.utc(2000,01,01,s.time_start/100,s.time_start.to_s[-2,2],00) unless s.time_start.nil?
      s.detailed_stop_time = Time.utc(2000,01,01,s.time_stop/100,s.time_stop.to_s[-2,2],00) unless s.time_stop.nil?
      s.save
    }
  end
end
