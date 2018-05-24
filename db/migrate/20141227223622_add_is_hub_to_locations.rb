# frozen_string_literal: true

class AddIsHubToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :is_hub, :boolean, :default => false, :null => false
  end
end
