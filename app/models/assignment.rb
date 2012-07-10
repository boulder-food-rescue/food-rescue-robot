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
end
