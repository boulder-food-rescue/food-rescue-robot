class AddDriverWaiver < ActiveRecord::Migration
  def up
    add_column :volunteers, :driver_waiver_signed, :boolean, default: false
    add_column :volunteers, :driver_waiver_signed_at, :datetime
  end

  def down
    remove_column :volunteers, :driver_waiver_signed, :driver_waiver_signed_at
  end
end
