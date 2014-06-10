class Schedule < ActiveRecord::Base

	include RankedModel
	
  has_many :schedule_volunteers # FIXME: remove after migrate
  has_many :logs
	belongs_to :location
	belongs_to :schedule_chain
	ranks :position, :with_same => :schedule_chain_id
  has_many :schedule_parts
  has_many :food_types, :through => :schedule_parts

  attr_accessible :food_type_ids, :location_id, :public_notes, :admin_notes, :expected_weight, :new

	def is_pickup_stop?
		return self.location.donor?
	end
  
end
