class InitScaleTypes < ActiveRecord::Migration
  def up
    Region.each{ |r|
    check = ScaleType.where('name = ?',"Guesstimate")
    check2 = ScaleType.where('region_id = ?',r.id)
    unless check.length >= 1
      t = ScaleType.new
      t.name = "Guesstimate"
      t.weight_unit = "lb"
      t.region_id=r.id
      t.save
    end
    }
  end

  def down
  end
end
