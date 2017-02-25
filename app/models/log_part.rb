class LogPart < ActiveRecord::Base
  belongs_to :log
  belongs_to :food_type
  attr_accessible :required, :weight, :count, :description, :food_type_id, :log_id

  # weight in db is always lbs, so convert to what the user expects to see (in the units of the scale)
  def scale_weight
    display_unit = self.log.scale_type.weight_unit
    if display_unit == 'kg'
      self.weight*2.2
    elsif display_unit == 'st'
      self.weight*14
    else
      self.weight
    end
  end

end
