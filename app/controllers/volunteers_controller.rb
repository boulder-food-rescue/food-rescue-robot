class VolunteersController < ApplicationController
  before_filter :authenticate_volunteer!

  def create_authorized?
    current_volunteer.super_admin? or current_volunteer.region_admin?
  end
#  def update_authorized?(record=nil)
#    return true if current_volunteer.super_admin?
#    record.regions.each{ |r|
#      return true if current_volunteer.region_admin?(r)
#    }
#    return false
#  end
#  def delete_authorized?(record=nil)
#    return true if current_volunteer.super_admin?
#    record.regions.each{ |r|
#      return true if current_volunteer.region_admin?(r)
#    }
#    return false
#  end

  active_scaffold :volunteer do |conf|
    conf.list.sorting = {:name => 'ASC'}
    conf.columns = [:name,:email,:phone,:preferred_contact,:gone_until,:has_car,:is_disabled, 
                    :admin,:on_email_list,:pickup_prefs,:transport_type,:admin_notes,:regions,:created_at]
    conf.columns[:is_disabled].label = "Account Deactivated"
    conf.columns[:preferred_contact].form_ui = :select
    conf.columns[:regions].form_ui = :select
    conf.columns[:transport_type].form_ui = :select
    conf.columns[:preferred_contact].options = {:options => [["Email","Email"],["Phone","Phone"],["Text","Text"]]}
  end

  # Custom views of the index table
  def unassigned
    @conditions = "(SELECT COUNT(*) FROM assignments a WHERE a.volunteer_id=volunteers.id)=0"
    index
  end
  def conditions_for_collection
    @conditions
  end

end 
