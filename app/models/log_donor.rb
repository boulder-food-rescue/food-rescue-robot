class LogDonor < ActiveRecord::Base

  belongs_to :log
  belongs_to :donor, :class_name => "Location", :foreign_key => "donor_id"

  attr_accessible :log_id, :donor_id, :active

  accepts_nested_attributes_for :donor

end