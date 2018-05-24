# frozen_string_literal: true

module RegionAdmin
  class DonorsController < ApplicationController
    before_filter :authenticate_volunteer!
    before_filter :authorize_region_admin!

    def index
      @locations = regional_donors
      @regions   = available_regions
    end

    private

    def regional_donors
      if current_volunteer.super_admin?
        Location.active.donors
      else
        Location.active.donors.regional(available_regions.map(&:id))
      end
    end

    def available_regions
      if current_volunteer.super_admin?
        Region.all
      else
        current_volunteer.assignments.collect{ |assignment| assignment.admin ? assignment.region : nil }.compact
      end
    end

    def authorize_region_admin!
      return if region_admin?
      redirect_to root_url, alert: 'Unauthorized'
    end

    def region_admin?
      current_volunteer.any_admin?
    end
  end
end
