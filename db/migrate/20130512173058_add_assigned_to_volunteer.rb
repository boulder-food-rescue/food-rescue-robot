# frozen_string_literal: true

class AddAssignedToVolunteer < ActiveRecord::Migration
  def up
    add_column :volunteers, :assigned, :boolean, :default => false, :null => false
    add_column :volunteers, :requested_region_id, :integer
    Assignment.all.each{ |a|
      unless a.volunteer.nil? or a.volunteer.assigned
        a.volunteer.assigned = true
        a.volunteer.save
      end
    }
  end

  def down
    remove_column :volunteers, :assigned
    remove_column :volunteers, :requested_region_id
  end
end
