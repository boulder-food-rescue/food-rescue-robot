class AddDonorAndRecipientToLog < ActiveRecord::Migration
  def change
    add_column :logs, :donor_id, :integer
    add_column :logs, :recipient_id, :integer
  end
end
