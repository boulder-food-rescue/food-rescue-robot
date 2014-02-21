class InitScaleTypes < ActiveRecord::Migration
  def up
    Region.each{ |r|
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
  end
end
