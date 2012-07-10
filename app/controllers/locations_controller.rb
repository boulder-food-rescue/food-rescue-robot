class LocationsController < ApplicationController
  before_filter :authenticate_volunteer!

  # Only admins can change things in the schedule table
  def create_authorized?
    current_volunteer.super_admin? or current_volunteer.region_admin?
  end
  def update_authorized?(record=nil)
    current_volunteer.super_admin? or current_volunteer.region_admin?(record.region)
  end
  def delete_authorized?(record=nil)
    current_volunteer.super_admin? or current_volunteer.region_admin?(record.region)
  end

  active_scaffold :location do |conf|
    conf.columns[:donor_type].form_ui = :select
    conf.columns[:donor_type].options = {:options => [["",nil],["Grocer","Grocer"],["Bakery","Bakery"],["Caterer","Caterer"],["Restaurant","Restaurant"],["Cafeteria","Cafeteria"],["Cafe","Cafe"],["Market","Market"],["Farm","Farm"],["Community Garden","Community Garden"],["Individual","Individual"],["Other","Other"]]}
    conf.columns[:recip_category].form_ui = :select
    conf.columns[:recip_category].options = {:options => [["",nil],["A","A"],["B","B"],["C","C"],["D","D"]]}
    conf.columns[:recip_category].label = 'Recipient Category'
    conf.columns[:recip_category].description = 'Leave blank if this is a donor'
    conf.columns[:donor_type].description = 'Leave blank if this is a recipient'
    conf.columns[:lat].label = 'Latitude'
    conf.columns[:lng].label = 'Longitude'
    conf.columns[:lat].description = 'Decimal degrees, WGS84, EPSG:4326, Leave blank for geo-coding'
    conf.columns[:lng].description = 'Decimal degrees, WGS84, EPSG:4326, Leave blank for geo-coding'
    conf.columns[:is_donor].description = "If this isn't checked, it must be a recipient"
    conf.columns[:region].form_ui = :select
  end

  def conditions_for_collection
    @base_conditions = "region_id IN (#{current_volunteer.assignments.collect{ |a| a.region_id }.join(",")})"
    @conditions.nil? ? @base_conditions : @base_conditions + " AND " + @conditions
  end
end 
