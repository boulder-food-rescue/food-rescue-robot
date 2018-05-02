class LogPart < ActiveRecord::Base
  belongs_to :log
  belongs_to :food_type
  belongs_to :location_admin

  attr_accessible :required, :weight, :count, :description, :food_type_id, :log_id, :location_admin_id, :compost_weight
end
