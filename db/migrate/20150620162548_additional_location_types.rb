class AdditionalLocationTypes < ActiveRecord::Migration
  def up
    change_table :locations do |t|
      t.integer :location_type, default: 0
    end
    execute 'UPDATE locations SET location_type=1 WHERE is_donor;'
    execute 'UPDATE locations SET location_type=2 WHERE is_hub;'
    remove_column :locations, :is_donor
    remove_column :locations, :is_hub
  end

  def down
    change_table :locations do |t|
      t.boolean :is_donor, default: false
      t.boolean :is_hub, default: false
    end
    execute "UPDATE locations SET is_donor = 't' WHERE location_type=1;"
    execute "UPDATE locations SET is_hub = 't' WHERE location_type=2;"
    remove_column :locations, :location_type
  end
end
