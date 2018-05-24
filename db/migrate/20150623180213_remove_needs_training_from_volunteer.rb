# frozen_string_literal: true

class RemoveNeedsTrainingFromVolunteer < ActiveRecord::Migration
  # obsolete fields
  def up
    remove_column :volunteers, :needs_training
    remove_column :volunteers, :gone_until
  end

  def down
    add_column :volunteers, :needs_training, :boolean, :default => false
    add_column :volunteers, :gone_until, :date
  end
end
