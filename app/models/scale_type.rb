class ScaleType < ActiveRecord::Base
  attr_accessible :name, :region_id, :weight_unit
  has_many :logs
  belongs_to :region

  default_scope { where(active:true) }
end
