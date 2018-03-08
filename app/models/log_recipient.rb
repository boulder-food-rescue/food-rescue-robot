class LogRecipient < ActiveRecord::Base

  belongs_to :log
  belongs_to :recipient, :class_name => 'Location', :foreign_key => 'recipient_id'

  attr_accessible :log_id, :recipient_id, :active, :log, :recipient

  accepts_nested_attributes_for :recipient

end
