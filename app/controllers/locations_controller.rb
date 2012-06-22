class LocationsController < ApplicationController
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

 
  end
end 
