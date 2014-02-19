class TieSchedulePartsToScales < ActiveRecord::Migration
  def up
    change_table :schedule_parts do |p|
      p.references :scale_type
    end
    add_index :schedule_parts, :scale_type_id
  end

  def down
  end
end
