module RegionsHelper
  def region_logo_column(record)
    return "" if record.logo_file_name.nil?
    image_tag(record.logo(:thumb))
  end
end
