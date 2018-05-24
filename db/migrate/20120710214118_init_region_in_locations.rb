# frozen_string_literal: true

class InitRegionInLocations < ActiveRecord::Migration
  def up
    br = Region.where('name = ?', 'Boulder').shift
    Location.all.each{ |l|
      l.region = br
      l.save
    }
  end

  def down
    Location.all.each{ |l|
      l.region = nil
    }
  end
end
