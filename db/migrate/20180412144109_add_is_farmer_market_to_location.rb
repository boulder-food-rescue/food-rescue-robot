class AddIsFarmerMarketToLocation < ActiveRecord::Migration
  def up
    add_column :locations, :is_farmer_market, :boolean, default: false
  end

  def down
    remove_column :locations, :is_farmer_market
  end
end
