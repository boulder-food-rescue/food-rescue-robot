class Schedule < ActiveRecord::Base
  belongs_to :volunteer
  belongs_to :prior_volunteer, :class_name => "Volunteer", :foreign_key => "prior_volunteer_id"
  belongs_to :donor, :class_name => "Location", :foreign_key => "donor_id"
  belongs_to :recipient, :class_name => "Location", :foreign_key => "recipient_id"
  belongs_to :transport_type
  belongs_to :region
  has_many :schedule_parts
  has_many :food_types, :through => :schedule_parts

  attr_accessible :region_id, :volunteer_id, :irregular, :backup, :transport_type_id, :food_type_ids, 
                  :weekdays, :admin_notes, :day_of_week, :donor_id, :prior_volunteer_id, :public_notes, 
                  :recipient_id, :detailed_start_time, :detailed_stop_time, :frequency, :detailed_date, :temporary,
                  :difficulty_rating, :expected_weight, :hilliness

  Hilliness = ["Flat","Mostly Flat","Some Small Hills","Hilly for Reals","Mountaineering"]
  Difficulty = ["Easiest","Typical","Challenging","Most Difficult"]

  def one_time?
    frequency=='one-time'
  end

  def weekly?
    frequency=='weekly'
  end

  def max_weight
    Log.where("schedule_id = ?",self.id).collect{ |l| l.summed_weight }.compact.max
  end

  def mean_weight
    ls = Log.where("schedule_id = ?",self.id).collect{ |l| l.summed_weight }
    ls.length == 0 ? nil : ls.sum/ls.length
  end

end
