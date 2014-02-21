class LogPart < ActiveRecord::Base
  belongs_to :log
  belongs_to :food_type
  belongs_to :scale_type
  attr_accessible :required, :weight, :count, :description, :food_type_id, :scale_type_id, :log_id

  before_save {
          scale = ScaleType.where('id = ?',self.log.scale_type_ids.first)
	  weight_unit = scale.first.weight_unit
	  conv_weight = self.weight.to_f
	  conv_weight = (conv_weight * (1/2.2).to_f) if weight_unit == "kg"
  	  conv_weight = (conv_weight * (1/14).to_f) if weight_unit == "st"
	  self.weight = conv_weight
  }
end
