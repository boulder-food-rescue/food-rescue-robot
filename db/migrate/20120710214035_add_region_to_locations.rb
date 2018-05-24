# frozen_string_literal: true

class AddRegionToLocations < ActiveRecord::Migration
  def change
    change_table :locations do |t|
      t.references :region
    end
  end
end
