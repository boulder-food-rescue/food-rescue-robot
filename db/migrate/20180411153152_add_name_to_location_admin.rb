class AddNameToLocationAdmin < ActiveRecord::Migration
  def up
    add_column :location_admins, :name, :string, default: false

  end

  def down
    remove_column :location_admins, :name, :phone
  end
end
