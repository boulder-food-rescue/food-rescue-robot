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
      t.string :weight_unit
    end
    Region.all.each{ |r|
      old_scales = Log.select("scale_type").where("region_id = ?",r).collect{ |l| l.scale_type }.uniq
      old_scales.each{ |s|
        sn = ScaleType.new
        sn.region_id = r.id
        sn.name = Log::ScaleTypes[s]
        sn.unit = "lb"
        sn.save
      }
      unless ScaleType.where('region_id = ?',r.id).length >= 1
        t = ScaleType.new
        t.name = "Bathroom Scale"
        t.weight_unit = "lb"
        t.region_id=r.id
        t.save

        t = ScaleType.new
        t.name = "Guesstimate"
        t.weight_unit = "lb"
        t.region_id=r.id
        t.save
      end
    }
  end

  def down
    change_table :logs do |t|
      t.remove :scale_type_id
    end
    drop_table :scale_types
  end
end