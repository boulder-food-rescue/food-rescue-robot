class LogPart < ActiveRecord::Base
  belongs_to :log
  belongs_to :food_type
  attr_accessible :required, :weight, :count, :description, :food_type_id, :log_id
end
