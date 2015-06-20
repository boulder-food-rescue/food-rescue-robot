class Absence < ActiveRecord::Base
  belongs_to :volunteer
  has_and_belongs_to_many :logs
  attr_accessible :start_date, :stop_date, :volunteer_id, :comments, :volunteer
end