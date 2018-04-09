class RenameDonorTableLocationAdmin < ActiveRecord::Migration
  def up
    rename_table :donors, :location_admin
  end

  def down
    rename_table :location_admin, :donors
  end
end
