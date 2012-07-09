class UseFoodTypesAndTransportTypes < ActiveRecord::Migration
  def up
    create_table :food_types_schedules do |t|
      t.references :food_type
      t.references :schedule
    end
    create_table :food_types_logs do |t|
      t.references :food_type
      t.references :log
    end
    change_table :logs do |t|
      t.references :transport_type
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
    end
    drop_table :food_types_schedules
    drop_table :food_types_logs
  end
end
