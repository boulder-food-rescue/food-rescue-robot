class AddRegionToLocationAdmin < ActiveRecord::Migration
  def up
    change_table :location_admins do |t|
      t.references :region
    end
  end

  def down
    remove_column :location_admins, :region_id
  end
end
