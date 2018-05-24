# frozen_string_literal: true

class Schedule < ActiveRecord::Base
  include RankedModel

  has_many :logs

  belongs_to :location
  belongs_to :schedule_chain
  ranks :position, with_same: :schedule_chain_id
  default_scope order('position ASC')

  has_many :schedule_parts
  has_many :food_types, through: :schedule_parts

  accepts_nested_attributes_for :food_types

  attr_accessible :food_type_ids, :location_id, :public_notes, :admin_notes, :expected_weight,
                  :schedule_chain_id, :position

  def pickup_stop?
    location.nil? ? false : Location::PICKUP_LOCATION_TYPES.include?(location.location_type)
  end

  def drop_stop?
    location.nil? ? false : Location::DROP_LOCATION_TYPES.include?(location.location_type)
  end
end
