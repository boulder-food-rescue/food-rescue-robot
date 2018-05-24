# frozen_string_literal: true

class TransportTypesController < ApplicationController
  before_filter :authenticate_volunteer!

  def index
    respond_to do |format|
      format.json { render json: TransportType.all.to_json }
    end
  end

end
