class Availability < ActiveRecord::Base
  belongs_to :volunteer
  attr_accessible :day, :time, :volunteer_id
  
end
