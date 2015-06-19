class AddDetailedHoursToLocation < ActiveRecord::Migration
  def change
    change_table :locations do |t|
      t.text :detailed_hours_json
    end
  end
end
