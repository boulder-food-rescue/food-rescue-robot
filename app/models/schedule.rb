class Schedule < ActiveRecord::Base
  belongs_to :volunteer
  belongs_to :prior_volunteer, :class_name => "Volunteer", :foreign_key => "prior_volunteer_id"
  belongs_to :donor, :class_name => "Location", :foreign_key => "donor_id"
  belongs_to :recipient, :class_name => "Location", :foreign_key => "recipient_id"

  # column-level restrictions
  def admin_notes_authorized?
    current_user.admin
  end

  # CRUD-level restrictions
  def authorized_for_update?
    current_user.admin
  end
  def authorized_for_create? 
    current_user.admin
  end
  def authorized_for_delete?
    current_user.admin
  end

  attr_accessible :admin_notes, :day_of_week, :donor_id, :needs_training, :prior_volunteer_id, :public_notes, :recipient_id, :time_start, :time_stop
end
