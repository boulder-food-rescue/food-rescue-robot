# frozen_string_literal: true

class AddPriorLbsRescuedToRegion < ActiveRecord::Migration
  def up
    change_table :regions do |t|
      t.integer :prior_lbs_rescued
      t.integer :prior_num_pickups
    end
  end

  def down
    remove_column :regions, :prior_lbs_rescued
    remove_column :regions, :prior_num_pickups
  end
end
