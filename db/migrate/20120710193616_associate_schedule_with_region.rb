# frozen_string_literal: true

class AssociateScheduleWithRegion < ActiveRecord::Migration
  def up
    change_table :schedules do |t|
      t.references :region
    end
    change_table :logs do |t|
      t.references :region
    end
  end

  def down
    remove_column :schedules, :region_id
    remove_column :logs, :region_id
  end
end
