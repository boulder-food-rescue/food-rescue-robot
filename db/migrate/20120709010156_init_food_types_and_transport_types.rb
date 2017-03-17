class InitFoodTypesAndTransportTypes < ActiveRecord::Migration
  def up
    tthash = {}
    # Make sure these are in there to start...
    %w(Bike Car Foot).each{ |v|
      check = TransportType.where('name = ?', v)
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
      s.transport = if s.transport_type.nil?
                      nil
                    else
                      s.transport_type.name
                    end
      s.save
    }
    Volunteer.all.each{ |v|
      v.transport = if v.transport_type.nil?
                      nil
                    else
                      v.transport_type.name
                    end
      v.save
    }
    Log.all.each{ |l|
      l.transport = if l.transport_type.nil?
                      nil
                    else
                      l.transport_type.name
                    end
      l.save
    }
  end
end
