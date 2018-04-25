class LogVolunteer < ActiveRecord::Base
  belongs_to :log
  belongs_to :volunteer

  attr_accessible :log_id, :volunteer_id, :active, :log, :volunteer, :covering

  accepts_nested_attributes_for :volunteer

  validate :prevent_active_duplicates

  private
  def prevent_active_duplicates
    existing_active = self.class.where(log_id: log_id, volunteer_id: volunteer_id, active: true)
    errors.add(:base, "volunteer #{volunteer_id} is already assigned to log #{log_id}") if active && existing_active.any?
  end
end
