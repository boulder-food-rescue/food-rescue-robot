class InitScaleTypes < ActiveRecord::Migration
  def up
    check = ScaleType.where('name = ?',"Guesstimate")
    unless check.length >= 1
      t = ScaleType.new
      t.name = "Guesstimate"
      t.weight_unit = "lb"
      t.save
    end
  end

  def down
  end
end
