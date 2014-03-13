class LogPart < ActiveRecord::Base
  belongs_to :log
  belongs_to :food_type
  attr_accessible :required, :weight, :count, :description, :food_type_id, :scale_type_id, :log_id


  before_save {
      if(self.log.region.scale_types.length==1)
        self.log.scale_type_id = self.log.region.scale_types.first.id
      end
      if scale_type_id.changed? 
        scale = ScaleType.where('id = ?',self.log.scale_type_id)
	    weight_unit = scale.first.weight_unit
  	    conv_weight = self.weight.to_f
  	    conv_weight = (conv_weight * (1/2.2).to_f) if weight_unit == "kg"
  	    conv_weight = (conv_weight * (1/14).to_f) if weight_unit == "st"
	    self.weight = conv_weight
      end
  }
end
