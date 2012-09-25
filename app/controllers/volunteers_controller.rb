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
    conf.columns = [:name,:photo,:email,:phone,:cell_carrier,:sms_too,:preferred_contact,:gone_until,:has_car,:is_disabled, 
                    :admin,:on_email_list,:pickup_prefs,:transport_type,:admin_notes,:regions,:created_at]
    conf.update.columns = [:name,:photo,:email,:phone,:cell_carrier,:preferred_contact,:sms_too,:pre_reminders_too,:gone_until,:has_car,:is_disabled,
                    :admin,:on_email_list,:pickup_prefs,:transport_type,:admin_notes,:regions]
    conf.columns[:is_disabled].label = "Account Deactivated"
    conf.columns[:sms_too].label = "Recieve Texts"
    conf.columns[:sms_too].description = "In addition to emails..."
    conf.columns[:pre_reminders_too].label = "Receive Pre-Reminders"
    conf.columns[:pre_reminders_too].description = "Remind about upcoming pickups"
    conf.columns[:preferred_contact].form_ui = :select
    conf.columns[:regions].form_ui = :select
    conf.columns[:cell_carrier].form_ui = :select
    conf.columns[:cell_carrier].clear_link
    conf.columns[:transport_type].form_ui = :select
    conf.columns[:preferred_contact].options = {:options => [["Email","Email"],["Phone","Phone"],["Text","Text"]]}
    conf.actions.exclude :create
    # if marking isn't enabled it creates errors on delete :(
    conf.actions.add :mark
  end

  def nested?
    return false
  end

  # Custom views of the index table
  def unassigned
    @conditions = "(SELECT COUNT(*) FROM assignments a WHERE a.volunteer_id=volunteers.id)=0"
    index
  end
  def shiftless
    my_rids = current_volunteer.regions.collect{ |r| r.id }
    @volunteers = Volunteer.where("NOT is_disabled AND (SELECT COUNT(*) FROM schedules s WHERE s.volunteer_id=volunteers.id)=0 AND 
                                   (gone_until IS NULL or gone_until < current_date)").collect{ |v| 
      (v.regions.collect{ |r| r.id } & my_rids).length > 0 ? v : nil }.compact
  end
  def shiftless_old
    @conditions = "(SELECT COUNT(*) FROM schedules s WHERE s.volunteer_id=volunteers.id)=0"
    index
  end
  def conditions_for_collection
    @conditions
  end

  # switch to a particular user
  def switch_user
    if current_volunteer.admin
      sign_out(current_volunteer)
      sign_in(Volunteer.find(params[:volunteer_id].to_i))
    end
    if not current_volunteer.admin
      redirect_to "/"
    else
      render :admin
    end
  end

  # special settings/stats page for admins only
  def admin
  end

end 
