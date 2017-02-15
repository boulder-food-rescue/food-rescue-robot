require File.join(__dir__, '../../lib/de_dup_log_volunteers.rb')
class PreventDuplicateLogVolunteers < ActiveRecord::Migration
  INDEX_NAME = 'index_log_volunteers_on_log_id_and_volunteer_id'
  def up
    DeDupLogVolunteers.de_duplicate
    ActiveRecord::Base.connection.execute <<-SQL
      CREATE UNIQUE INDEX "#{INDEX_NAME}"
      ON "log_volunteers" ("log_id", "volunteer_id")
      WHERE active is true
    SQL
  end
  def down
    remove_index :log_volunteers, name: INDEX_NAME
  end
end
