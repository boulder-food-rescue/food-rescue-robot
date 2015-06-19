class AddNumVolunteersToLog < ActiveRecord::Migration
  def change
    add_column :logs, :num_volunteers, :integer
  end
end
