class CreateLogVolunteers < ActiveRecord::Migration
  def up
    # make the new one-to-many table
    create_table :log_volunteers do |t|
      t.integer :log_id
      t.integer :volunteer_id
      t.boolean :active, :default=>true
      t.timestamps
    end
    # add some default indices
    add_index :log_volunteers, [:log_id]
    add_index :log_volunteers, [:volunteer_id]
    # now migrate data (do it with raw data cause the model class is changing)
    Log.select('id,volunteer_id,orig_volunteer_id').each do |log|
      unless log.volunteer_id.blank?
        logVolunteer = LogVolunteer.new
        logVolunteer.volunteer_id = log.volunteer_id
        logVolunteer.log_id = log.id
        logVolunteer.active = true
        logVolunteer.save
      end
      unless log.orig_volunteer_id.blank?
        logVolunteer = LogVolunteer.new
        logVolunteer.volunteer_id = log.orig_volunteer_id
        logVolunteer.log_id = log.id
        logVolunteer.active = false
        logVolunteer.save
      end
    end
    # and verify that it worked
    a = Log.count('volunteer_id>0')+Log.count('orig_volunteer_id>0')
    b = LogVolunteer.count
    if a == b
      remove_column(:logs, :volunteer_id)
      remove_column(:logs, :orig_volunteer_id)
    else
      raise "ERROR: Log count (#{a}) and new LogVolunteer count (#{b}) don't match :-("
    end
  end

  def down
    drop_table :log_volunteers
    # doesn't actually return data to what it was, but at least sets the columns back
    add_column(:logs, :volunteer_id, :integer)
    add_column(:logs, :orig_volunteer_id, :integer)
  end

end
