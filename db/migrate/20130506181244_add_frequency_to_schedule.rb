class AddFrequencyToSchedule < ActiveRecord::Migration
  def change
    change_table :schedules do |t|
      t.text :frequency
    end
  end
end
