class CreateScheduleVolunteers < ActiveRecord::Migration

  def up
    # make the new one-to-many table
    create_table :schedule_volunteers do |t|
      t.integer :schedule_id
      t.integer :volunteer_id
      t.boolean :active, :default=>true
      t.timestamps
    end
    # add some default indices
    add_index :schedule_volunteers, [:schedule_id]
    add_index :schedule_volunteers, [:volunteer_id]
    # now migrate data (do it with raw data cause the model class is changing)
    schedule_info = ActiveRecord::Base.connection.execute('SELECT id, volunteer_id, prior_volunteer_id FROM schedules')
    schedule_info.each do |schedule|
      if not schedule['volunteer_id'].nil? and not schedule['volunteer_id'].blank?
        scheduleVolunteer = ScheduleVolunteer.new
        scheduleVolunteer.volunteer_id = schedule['volunteer_id']
        scheduleVolunteer.schedule_id = schedule['id']
        scheduleVolunteer.active = true
        scheduleVolunteer.save
      end
      if not schedule['prior_volunteer_id'].nil? and not schedule['prior_volunteer_id'].blank?
        scheduleVolunteer = ScheduleVolunteer.new
        scheduleVolunteer.volunteer_id = schedule['volunteer_id']
        scheduleVolunteer.schedule_id = schedule['id']
        scheduleVolunteer.active = false
        scheduleVolunteer.save
      end
    end
    # and verify that it worked
    if (Schedule.count('volunteer_id > 0')+Schedule.count('prior_volunteer_id > 0')) == ScheduleVolunteer.count
      remove_column(:schedules, :volunteer_id)
      remove_column(:schedules, :prior_volunteer_id)
    else
      raise "ERROR: Schedule count and new ScheduleVolunteer count don't match :-("
    end
  end

  def down
    drop_table :schedule_volunteers
    # doesn't actually return data to what it was, but at least sets the columns back
    add_column(:schedules, :volunteer_id, :integer)
    add_column(:schedules, :prior_volunteer_id, :integer)
  end

end
