class AddCompostToLogParts < ActiveRecord::Migration
  def up
    add_column :log_parts, :compost_weight, :decimal, default: 0
  end

  def down
    remove_column :log_parts, :compost_weight
  end
end
