class MakeFoodTypesRegional < ActiveRecord::Migration
  def up
    change_table :food_types do |t|
      t.references :region
    end
    Region.all.each{ |r|
      FoodType.where("region_id IS NULL").each{ |ft|
        ftnew = FoodType.new
        ftnew.region_id = r.id
        ftnew.name = ft.name
        ftnew.save
        execute "UPDATE schedule_parts SET food_type_id=#{ftnew.id} FROM schedules s WHERE food_type_id=#{ft.id} AND s.id=schedule_id AND s.region_id=#{r.id};"
        execute "UPDATE log_parts SET food_type_id=#{ftnew.id} FROM logs l WHERE food_type_id=#{ft.id} AND l.id=log_id AND l.region_id=#{r.id};"
      }
    }
  end
  def down
    execute "DELETE FROM food_types WHERE region_id IS NOT NULL"
    remove_column :food_types, :region_id
    
  end
end
