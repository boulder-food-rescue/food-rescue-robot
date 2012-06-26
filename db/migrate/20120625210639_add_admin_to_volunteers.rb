class AddAdminToVolunteers < ActiveRecord::Migration
  def change
    add_column :volunteers, :admin, :boolean, :default => false
  end
end
