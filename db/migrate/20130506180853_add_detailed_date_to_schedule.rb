class AddDetailedDateToSchedule < ActiveRecord::Migration
  def change
    change_table :schedules do |t|
      t.date :detailed_date
    end
  end
end
