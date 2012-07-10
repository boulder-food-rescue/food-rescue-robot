class Assignment < ActiveRecord::Base
  belongs_to :volunteer
  belongs_to :region
  attr_accessible :admin
end
