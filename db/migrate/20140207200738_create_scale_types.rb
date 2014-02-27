class CreateScaleTypes < ActiveRecord::Migration
  def up
    create_table :scale_types do |t|
      t.string :name
      t.string :weight_unit
      t.timestamps
      t.references :region
    end
		change_table :logs do |t|
      t.references :scale_type
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
		Region.all.each{ |r|
    	defaultName = "Bathroom Scale (default)"
    	check = ScaleType.where('name = ?',defaultName)
    	check2 = ScaleType.where('region_id = ?',r.id)
    	unless check.length >= 1
      	t = ScaleType.new
      	t.name = defaultName
      	t.weight_unit = "lb"
      	t.region_id=r.id
      	t.save
    	end
    }
  end

	def down
		execute "DELETE FROM scale_types WHERE region_id IS NOT NULL"
    remove_column :scale_types, :region_id
		change_table :logs do |t|
      t.remove :scale_type
    end
		drop_table :scale_types
	end
