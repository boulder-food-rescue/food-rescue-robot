module VolunteersHelper

  def volunteer_photo_column(record)
    return "" if record.photo_file_name.nil?
    link_to image_tag(record.photo(:thumb)){ record.photo(:medium) }
  end

end
