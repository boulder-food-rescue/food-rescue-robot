class MoveNeedsTrainingToVolunteer < ActiveRecord::Migration
  def up
    change_table :volunteers do |t|
      t.boolean :needs_training, :default => true
    end
    # if they've done a pickup successfully, they clearly don't need to be trained
    Log.where('weight is not NULL').each{ |l|
      next if l.volunteer.nil?
      next unless l.volunteer.needs_training
      l.volunteer.needs_training = false
      l.volunteer.save
    }
    Schedule.where('needs_training').each{ |s|
      next if s.volunteer.nil?
      s.volunteer.needs_training = true
      s.volunteer.save
    }
    remove_column :schedules, :needs_training
  end

  def down
    change_table :schedules do |t|
      t.boolean :needs_training
    end
    remove_column :volunteers, :needs_training
  end
end
