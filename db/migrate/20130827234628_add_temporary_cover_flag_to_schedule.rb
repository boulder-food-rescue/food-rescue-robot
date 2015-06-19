class AddTemporaryCoverFlagToSchedule < ActiveRecord::Migration
  def change
    change_table :schedules do |t|
      t.boolean :temporary, :default => false
    end
  end
end
