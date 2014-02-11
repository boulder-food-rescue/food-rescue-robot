class MakeScaleTypesRegional < ActiveRecord::Migration
  def up
    change_table :scale_types do |t|
      t.references :region
    end
  Region.all.each{ |r|
    ScaleType.where("region_id IS NULL").each{ |st|
      stnew = ScaleType.new
      stnew.region_id = r.id
      stnew.name = st.name
      stnew.save
      execute "UPDATE schedule_parts SET scale_type_id=#{stnew.id} FROM schedules s WHERE scale_type_id=#{st.id} AND s.id=schedule_id AND s.region_id=#{r.id};"
      execute "UPDATE log_parts SET scale_type_id=#{stnew.id} FROM logs l WHERE scale_type_id=#{st.id} AND l.id=log_id AND l.region_id=#{r.id};"
      }
    }
  end

  def down
    execute "DELETE FROM scale_types WHERE region_id IS NOT NULL"
    remove_column :scale_types, :region_id
  end
end
