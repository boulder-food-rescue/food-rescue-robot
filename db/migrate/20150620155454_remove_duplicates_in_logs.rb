# frozen_string_literal: true

class RemoveDuplicatesInLogs < ActiveRecord::Migration
  def up
    kill_count = 0
    Log.all.each{ |l|
      v = []
      l.log_volunteers.each{ |lv|
        unless v.include? lv.volunteer_id
          v.push lv.volunteer_id
        else
          kill_count += 1
          lv.destroy
        end
      }
      r = []
      l.log_recipients.each{ |lr|
        unless r.include? lr.recipient_id
          r.push lr.recipient_id
        else
          kill_count += 1
          lr.destroy
        end
      }
    }
    puts "Killed #{kill_count} duplicates"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
