class Assignment < ActiveRecord::Base
  belongs_to :volunteer
  belongs_to :region
  attr_accessible :admin

  # CRUD-level restrictions
  def authorized_for_update?
    current_user.admin or current_user.region_admin?(self.region)
  end

  def authorized_for_create?
    current_user.admin or current_user.region_admin?(self.region)
  end

  def authorized_for_delete?
    current_user.admin or current_user.region_admin?(self.region)
  end

  def self.add_volunteer_to_region volunteer, region
    return false if volunteer.new_record?
    if Assignment.where(volunteer_id: volunteer, region_id: region.id).count == 0
      a = Assignment.new
      a.volunteer = volunteer
      a.region = region
      a.save
    end
    volunteer.assigned = true
    volunteer.save
    return true
  end

end
