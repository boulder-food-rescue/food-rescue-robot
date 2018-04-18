class AddLocationAdminIdToScheduleParts < ActiveRecord::Migration
  def up
    change_table :schedule_parts do |t|
      t.references :location_admin
    end
  end

  def down
    remove_column :schedule_parts, :location_admin_id
  end
end
