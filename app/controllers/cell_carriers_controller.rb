# frozen_string_literal: true

class CellCarriersController < ApplicationController
  before_filter :authenticate_volunteer!

  active_scaffold :cell_carrier do |conf|
    conf.columns = [:name, :format]
  end

  def create_authorized?
    current_volunteer.super_admin?
  end

  def update_authorized?(_record=nil)
    current_volunteer.super_admin?
  end

  def delete_authorized?(_record=nil)
    current_volunteer.super_admin?
  end
end
