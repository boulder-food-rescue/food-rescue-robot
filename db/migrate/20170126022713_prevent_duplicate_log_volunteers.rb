class PreventDuplicateLogVolunteers < ActiveRecord::Migration
  # This adds a uniqueness constraint to table log_volunteers
  # Be sure to run de-duplication first: `rake db:cleanup:log_volunteers`
  def change
    add_index :log_volunteers, [:log_id, :volunteer_id], unique: true
  end
end
