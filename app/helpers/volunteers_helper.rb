module VolunteersHelper
  def volunteer_photo_column(record)
    return '' if record.photo_file_name.nil?
    link_to image_tag(record.photo(:thumb)){ record.photo(:medium) }
  end

  # RB 3-23-2018: Return volunteers that are unassigned
  # and only in the region ids that are passed in
  # all super admins are filtered out for security purposes
  def my_admin_volunteers
    return Volunteer.all if current_volunteer.super_admin?

    unassigned = Volunteer.not_super_admin.unassigned.where(assignments: { admin: false })

    volunteers_in_regions = Volunteer.not_super_admin
                                     .assigned_to_regions(current_volunteer.admin_region_ids)
                                     .where(assignments: { admin: false })

    (volunteers_in_regions + unassigned).uniq
  end
end
