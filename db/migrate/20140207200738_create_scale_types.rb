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
    old_scales = Log.select("scale_type").where("region_id = ?",r).collect{ |l| l.scale_type }.uniq
    old_scales.each{ |s|
      sn = ScaleType.new
      sn.region_id = r.id
      sn.name = Log::ScaleTypes[s]
      sn.unit = "lb"
      sn.save
      Log.where("region_id = ? and scale_type = ?",r.id,s).each{ |ol|
        ol.scale_type_id = sn.id
        ol.save
      }
    }
    Region.all.each{ |r|
      #defaultName = "Bathroom Scale [default]"
      #check = ScaleType.where('name = ?',defaultName)
      #check = check.where('region_id = ?',r.id)
      unless ScaleType.where('region_id = ?',r.id).length >= 1
        t = ScaleType.new
        t.name = defaultName
        t.weight_unit = "lb"
        t.region_id=r.id
        t.save
      #end
      #defaultName = "Guesstimate [default]"
      #check = ScaleType.where('name = ?',defaultName)
      #check = check.where('region_id = ?',r.id)
      #unless check.length >= 1
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
end
