class AddUnitsToFoodTypes < ActiveRecord::Migration
  def change
    add_column :regions, :weight_unit, :string, :null => false, :default => 'pound'
    add_column :log_parts, :count, :integer
    add_column :log_parts, :description, :text
    Log.all.each{ |l|
      next if l.description.nil?
      l.log_parts.each{ |lp| 
        lp.description = l.description
        lp.save
        break
      }
    }
    remove_column :logs, :description
  end
end
