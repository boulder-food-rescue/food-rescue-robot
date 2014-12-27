class AddNumVolunteersToScheduleChain < ActiveRecord::Migration
  def change
    add_column :schedule_chains, :num_volunteers, :integer, :default => 1, :null => false
  end
end
