class AssociateLogPartsWithWeightUnits < ActiveRecord::Migration
  def up
    change_table :log_parts do |l|
      l.references :weight_unit
    end
  end

  def down
    change_table :log_parts do |l|
      l.remove :weight_unit
    end
  end
end
