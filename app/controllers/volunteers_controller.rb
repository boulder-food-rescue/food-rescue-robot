class VolunteersController < ApplicationController
  before_filter :authenticate_volunteer!

  def create_authorized?
    current_volunteer.admin
  end
  def update_authorized?(record=nil)
    current_volunteer.admin
  end
  def delete_authorized?(record=nil)
    current_volunteer.admin
  end

  active_scaffold :volunteer do |conf|
    conf.list.sorting = {:name => 'ASC'}
    conf.columns = [:name,:email,:phone,:preferred_contact,:gone_until,:has_car,:is_disabled,:admin,:on_email_list,:pickup_prefs,:transport,:admin_notes]
    conf.columns[:is_disabled].label = "Account Deactivated"
    conf.columns[:transport].form_ui = :select
    conf.columns[:transport].label = "Preferred Transportation"
    conf.columns[:transport].options = {:options => [["Bike","Bike"],["Car","Car"],["Foot","Foot"]]}
    conf.columns[:preferred_contact].form_ui = :select
    conf.columns[:preferred_contact].options = {:options => [["Email","Email"],["Phone","Phone"],["Text","Text"]]}
  end
end 
