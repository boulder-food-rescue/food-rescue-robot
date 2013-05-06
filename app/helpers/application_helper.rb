module ApplicationHelper

  def all_admin_region_volunteer_tuples(whom)
    admin_rids = whom.assignments.collect{ |a| a.admin ? a.region.id : nil }.compact
    Volunteer.all.collect{ |v|
      v_rids = v.regions.collect{ |r| r.id }
      (admin_rids & v_rids).length > 0 ? [v.name+" ["+v.regions.collect{ |r| r.name }.join(",")+"]",v.id] : nil
    }.compact
  end

  def use_detailed_hours?
    Webapp::Application.config.use_detailed_hours
  end

end
