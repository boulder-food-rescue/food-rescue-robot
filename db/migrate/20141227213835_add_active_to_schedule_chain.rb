class AddActiveToScheduleChain < ActiveRecord::Migration
  def change
    add_column :schedule_chains, :active, :boolean, :null => false, :default => true
    add_column :locations, :active, :boolean, :null => false, :default => true
    add_column :volunteers, :active, :boolean, :null => false, :default => true
    add_column :scale_types, :active, :boolean, :null => false, :default => true
    add_column :transport_types, :active, :boolean, :null => false, :default => true
    add_column :food_types, :active, :boolean, :null => false, :default => true
  end
end
