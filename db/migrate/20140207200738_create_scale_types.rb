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
    execute "UPDATE logs SET weight_unit='lb'"
    Region.all.each{ |r|
      Log.select("weighed_by").where("region_id = ?",r).collect{ |l| l.weighed_by }.uniq.each{ |s|
        next if s.squish.blank?
        sn = ScaleType.new
        sn.region_id = r.id
        sn.name = s
        sn.weight_unit = "lb"
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
    remove_column :logs, :weighed_by
  end

  def down
    # doesn't restore data
    change_table :logs do |t|
      t.remove :scale_type_id
    end
    drop_table :scale_types
    add_column :logs, :weighed_by, :string
  end
end