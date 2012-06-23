module SchedulesHelper
  def schedule_time_start_column(record)
    sprintf("%04d",record.time_start)
  end
  def schedule_time_stop_column(record)
    sprintf("%04d",record.time_stop)
  end
  def schedule_recipient_column_attributes(record)
    if record.recipient.nil?
      {:style => 'background: yellow;'}
    else
      {}
    end
  end
  def schedule_donor_column_attributes(record)
    if record.donor.nil?
      {:style => 'background: yellow;'}
    else
      {}
    end
  end
  def schedule_volunteer_column_attributes(record)
    if record.volunteer.nil?
      {:style => 'background: yellow;'}
    else
      {}
    end
  end
end
