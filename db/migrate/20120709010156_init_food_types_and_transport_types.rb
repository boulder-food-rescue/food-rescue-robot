class InitFoodTypesAndTransportTypes < ActiveRecord::Migration
  def up
    tthash = {}
    # Make sure these are in there to start...
    ["Bike","Car","Foot"].each{ |v|
      check = TransportType.where('name = ?',v)
      unless check.length >= 1
        t = TransportType.new
        t.name = v
        t.save
        tthash[v] = t
      else
        tthash[v] = check.shift
      end
    }

    Schedule.all.each{ |s|
      s.transport_type = tthash[s.transport]
      s.save
    }
    Log.all.each{ |l|
      l.transport_type = tthash[l.transport]
      l.save
    }
    Volunteer.all.each{ |v|
      v.transport_type = tthash[v.transport]
      v.save
    }

    change_table :logs do |t|
      t.remove :transport
    end
    change_table :volunteers do |t|
      t.remove :transport
    end
    change_table :schedules do |t|
      t.remove :transport
    end
  end

  def down
    change_table :logs do |t|
      t.string :transport
    end
    change_table :schedules do |t|
      t.string :transport
    end
    change_table :volunteers do |t|
      t.string :transport
    end

    Schedule.all.each{ |s|
      if s.transport_type.nil?
        s.transport = nil
      else
        s.transport = s.transport_type.name
      end
      s.save
    }
    Volunteer.all.each{ |v|
      if v.transport_type.nil?
        v.transport = nil
      else
        v.transport = v.transport_type.name
      end
      v.save
    }
    Log.all.each{ |l|
      if l.transport_type.nil?
        l.transport = nil
      else
        l.transport = l.transport_type.name
      end
      l.save
    }
  end
end
