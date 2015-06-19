class AddPickupInfo < ActiveRecord::Migration
  def change
    change_table :locations do |t|
      t.text :equipment_storage_info
      t.text :food_storage_info
      t.text :entry_info
      t.text :exit_info
      t.text :onsite_contact_info
    end
    change_table :schedules do |t|
      t.integer :difficulty_rating
      t.integer :expected_weight
      t.integer :hilliness
    end
  end
end
