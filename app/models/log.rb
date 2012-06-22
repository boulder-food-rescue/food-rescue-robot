class Log < ActiveRecord::Base
  belongs_to :schedule
  belongs_to :volunteer
  attr_accessible :description, :flag_for_admin, :notes, :num_reminders, :orig_volunteer_id, :transport, :weighed_by, :weight, :when
end
