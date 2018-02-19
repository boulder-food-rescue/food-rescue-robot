class AddAdminDriverWaiverSignatureToVolunteer < ActiveRecord::Migration
  def up
    add_column :volunteers, :driver_waiver_signed_by_admin_name, :text
    add_column :volunteers, :driver_waiver_signed_by_admin_at, :datetime
  end

  def down
    remove_column :volunteers, :driver_waiver_signed_by_admin_name, :driver_waiver_signed_by_admin_at
  end
end
