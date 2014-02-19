class AssociateLogPartsWithScales < ActiveRecord::Migration
  def up
    create_table :scale_types_schedules do |t|
      t.references :scale_type
      t.references :schedule
    end
    change_table :log_parts do |t|
      t.references :scale_type
    end
  end
  def down
    drop_table :scale_types_schedules
    change_table :log_parts do |t|
      t.remove :scale_type
    end
  end
end
