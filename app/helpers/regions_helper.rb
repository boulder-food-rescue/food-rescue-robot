# frozen_string_literal: true

module RegionsHelper
  def region_logo_column(record)
    return '' if record.logo_file_name.nil?
    image_tag(record.logo(:thumb))
  end

  def region_time_zone_form_column(record, options)
    time_zone_select( 'record', 'time_zone', ActiveSupport::TimeZone.us_zones,
                      {:default => record.time_zone}, options)
  end
end
