# frozen_string_literal: true

class TransportType < ActiveRecord::Base
  attr_accessible :name
  default_scope { where(active: true) }
end
