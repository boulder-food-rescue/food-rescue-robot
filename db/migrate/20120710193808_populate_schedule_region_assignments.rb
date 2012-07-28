class PopulateScheduleRegionAssignments < ActiveRecord::Migration
  def up
    br = Region.where("name = ?","Boulder").shift
    Schedule.all.each{ |s|
      s.region = br
      s.save
    }
    Log.all.each{ |l|
      l.region = br
      l.save
    }
  end

  def down
    Schedule.all.each{ |s|
      s.region = nil
      s.save
    }
    Log.all.each{ |l|
      l.region = nil
      l.save
    }
  end
end
