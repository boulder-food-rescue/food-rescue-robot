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
end
