class AddWaiverSignedToVolunteers < ActiveRecord::Migration
  def up
    add_column :volunteers, :waiver_signed, :boolean, :null => false, :default => 'f'
    add_column :volunteers, :waiver_signed_at, :datetime
  end

  def down
    remove_column :volunteers, :waiver_signed
    remove_column :volunteers, :waiver_signed_at
  end
end
