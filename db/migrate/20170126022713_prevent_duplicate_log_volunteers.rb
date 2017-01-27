require File.join(__dir__, '../../lib/de_dup_log_volunteers.rb')
class PreventDuplicateLogVolunteers < ActiveRecord::Migration
  def up
    DeDupLogVolunteers.de_duplicate
    add_index :log_volunteers, [:log_id, :volunteer_id], unique: true
  end
  def down
    remove_index :log_volunteers, column: [:log_id, :volunteer_id]
  end
end
