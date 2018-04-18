class AddLocationAdminIdToLogParts < ActiveRecord::Migration
  def up
    change_table :log_parts do |t|
      t.references :location_admin
    end
  end

  def down
    remove_column :log_parts, :location_admin_id
  end
end
