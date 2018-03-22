module RegionsHelper

  def region_time_zone_form_column(record, options)
    time_zone_select( 'record', 'time_zone', ActiveSupport::TimeZone.us_zones,
      {:default => record.time_zone}, options)
  end

end
