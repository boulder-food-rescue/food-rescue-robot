class Log < ActiveRecord::Base
  belongs_to :schedule
  belongs_to :volunteer
  belongs_to :orig_volunteer, :foreign_key => "orig_volunteer_id", :class_name => "Volunteer"
  belongs_to :donor, :class_name => "Location", :foreign_key => "donor_id"
  belongs_to :recipient, :class_name => "Location", :foreign_key => "recipient_id"
  attr_accessible :description, :flag_for_admin, :notes, :num_reminders, :orig_volunteer_id, :transport, :weighed_by, :weight, :when

  # ActiveScaffold CRUD-level restrictions
  def authorized_for_update?
    current_user.admin or current_user.email == self.volunteer.email
  end
  def authorized_for_create?
    current_user.admin or current_user.email == self.volunteer.email
  end
  def authorized_for_delete?
    current_user.admin
  end

end
