class LogPart < ActiveRecord::Base
  belongs_to :log
  belongs_to :food_type
  belongs_to :scale_type
  attr_accessible :required, :weight, :count, :description, :food_type_id, :scale_type_id, :log_id
end
