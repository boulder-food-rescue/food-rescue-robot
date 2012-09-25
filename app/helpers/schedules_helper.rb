module SchedulesHelper
  def schedule_time_start_column(record)
    record.time_start.nil? ? "?" : sprintf("%04d",record.time_start)
  end
  def schedule_time_stop_column(record)
    record.time_stop.nil? ? "?" : sprintf("%04d",record.time_stop)
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
      {:style => 'background: #F57A7A;'}
    elsif record.needs_training
      {:style => 'background: lightgreen;'}
    else
      {}
    end
  end

  def schedule_volunteer_column(record)
    if record.volunteer.nil?
      link_to "Take Shift", "/schedules/#{record.id}/take"
    else
      link_to record.volunteer.name, "/volunteers/#{record.volunteer.id}?association=volunteer&schedule_id=#{record.id}&parent_scaffold=schedules",
            "class" => "show as_action volunteer", "data-action" => "show", "data-remote" => "true", "data-position" => "after",
            "id" => "as_schedules-show-volunteer-#{record.volunteer.id}-#{record.id}-link"
    end
  end

  # These add "show" links for donor, recipient, and prior_volunteer
  def schedule_donor_column(record)
    if record.donor.nil?
      "-"
    else
      link_to record.donor.name, "/locations/#{record.donor.id}?association=donor&log_id=#{record.id}&parent_scaffold=schedules",
              "class" => "show as_action donor", "data-action" => "show", "data-remote" => "true", "data-position" => "after",
              "id" => "as_schedules-show-donor-#{record.donor.id}-#{record.id}-link"
    end
  end

  def schedule_recipient_column(record)
    if record.recipient.nil?
      "-"
    else
      link_to record.recipient.name, "/locations/#{record.recipient.id}?association=recipient&log_id=#{record.id}&parent_scaffold=schedules",
              "class" => "show as_action recipient", "data-action" => "show", "data-remote" => "true", "data-position" => "after",
              "id" => "as_schedules-show-recipient-#{record.recipient.id}-#{record.id}-link"
    end
  end

  def schedule_prior_volunteer_column(record)
    if record.prior_volunteer.nil?
      "-"
    else
      link_to record.prior_volunteer.name, "/volunteers/#{record.prior_volunteer.id}?association=prior_volunteer&schedule_id=#{record.id}&parent_scaffold=schedules",
              "class" => "show as_action prior_volunteer", "data-action" => "show", "data-remote" => "true", "data-position" => "after",
              "id" => "as_schedules-show-prior_volunteer-#{record.prior_volunteer.id}-#{record.id}-link"
    end
  end

end
