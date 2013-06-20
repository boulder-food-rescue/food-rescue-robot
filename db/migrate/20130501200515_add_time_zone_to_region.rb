class AddTimeZoneToRegion < ActiveRecord::Migration
  def change
    change_table :regions do |t|
      t.text :time_zone
    end
  end
end
