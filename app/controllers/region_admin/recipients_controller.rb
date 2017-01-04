module RegionAdmin
  class RecipientsController < ApplicationController
    before_filter :authenticate_volunteer!
    before_filter :authorize_region_admin!

    def index
      @locations = regional_recipients
      @regions   = available_regions
    end

    private

    def regional_recipients
      if current_volunteer.super_admin?
        Location.active.recipients
      else
        Location.active.recipients.regional(available_regions.map(&:id))
      end
    end

    def available_regions
      if current_volunteer.super_admin?
        Region.all
      else
        current_volunteer.assignments.collect{ |a| a.admin ? a.region : nil }.compact
      end
    end

    def authorize_region_admin!
      return if region_admin?
      redirect_to root_url, alert: "Unauthorized"
    end

    def region_admin?
      current_volunteer.any_admin?
    end
  end
end
