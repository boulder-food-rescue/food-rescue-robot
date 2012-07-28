class UseFoodTypesAndTransportTypes < ActiveRecord::Migration
  def up
    create_table :food_types_schedules do |t|
      t.references :food_type
      t.references :schedule
    end
    change_table :logs do |t|
      t.references :transport_type
      t.references :food_type
    end
    change_table :schedules do |t|
      t.references :transport_type
    end
    change_table :volunteers do |t|
      t.references :transport_type
    end
  end
  def down
    change_table :volunteers do |t|
      t.remove :transport_type_id
    end
    change_table :schedules do |t|
      t.remove :transport_type_id
    end
    change_table :logs do |t|
      t.remove :transport_type_id
      t.remove :food_type_id
    end
    drop_table :food_types_schedules
  end
end
