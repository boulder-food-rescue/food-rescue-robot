class AddUnitsToFoodTypes < ActiveRecord::Migration
  def change
    add_column :regions, :weight_unit, :string, :null => false, :default => 'pound'
    add_column :log_parts, :count, :integer
    add_column :log_parts, :description, :string
  end
end
