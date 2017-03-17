class PopulateAssignmentsAndRegions < ActiveRecord::Migration
  def up
    rb = Region.new
    rb.name = 'Boulder'
    rb.address = 'Boulder, Colorado, USA'
    rb.website = 'http://boulderfoodrescue.org'
    rb.save

    rd = Region.new
    rd.name = 'Denver'
    rd.address = 'Denver, Colorado, USA'
    rd.website = 'http://denverfoodrescue.org'
    rd.save

    Volunteer.all.each{ |e|
      a = Assignment.new
      a.volunteer = e
      a.region = rb
      a.admin = e.admin
      a.save
    }
  end

  def down
    Assignment.delete_all
    Region.delete_all
  end
end
