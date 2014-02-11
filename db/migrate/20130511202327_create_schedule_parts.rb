class CreateScheduleParts < ActiveRecord::Migration
  def up
    create_table :schedule_parts do |t|
      t.references :schedule
      t.references :food_type
      t.boolean :required

      t.timestamps
    end
    add_index :schedule_parts, :schedule_id
    add_index :schedule_parts, :food_type_id
    add_index :schedule_parts, :scale_type_id

    execute "INSERT INTO schedule_parts (food_type_id,schedule_id,created_at,updated_at) 
             SELECT food_type_id,schedule_id,'now','now' FROM food_types_schedules;"
    drop_table :food_types_schedules    
  end
  def down
    create_table :food_types_schedules do |t|
      t.references :schedule
      t.references :food_type
    end
    drop_table :schedule_parts
  end
end
