# frozen_string_literal: true

module VolunteersHelper
  def volunteer_photo_column(record)
    return '' if record.photo_file_name.nil?
    link_to image_tag(record.photo(:thumb)){ record.photo(:medium) }
  end

  # RB 3-23-2018: Return volunteers that are unassigned
  # and in current volunteer's region(s).
  # All super admins are filtered out for security purposes
  def my_admin_volunteers
    return Volunteer.all if current_volunteer.super_admin?

    unassigned = Volunteer.not_super_admin
                          .unassigned

    volunteers_in_regions = Volunteer.not_super_admin
                                     .assigned_to_regions(current_volunteer.admin_region_ids)

    (volunteers_in_regions + unassigned).uniq
  end

  def adminable_active_volunteers
    return Volunteer.active if current_volunteer.super_admin?
    Volunteer.not_super_admin.active(current_volunteer.region_ids)
  end
end
