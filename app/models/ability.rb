class Ability
  include CanCan::Ability

  def initialize(volunteer)
    @volunteer = volunteer

    super_admin_permissions if super_admin?
    region_admin_permissions if region_admin?
  end

  private

  attr_reader :volunteer

  def super_admin?
    volunteer.admin?
  end

  def super_admin_permissions
    can :manage, :all
  end

  def region_admin?
    volunteer.any_admin?
  end

  def region_admin_permissions
    can :update, Region, id: admin_region_ids
    can :manage, Location, region_id: admin_region_ids
    can :manage, FoodType, region_id: admin_region_ids
    can :manage, ScaleType, region_id: admin_region_ids
  end

  def assignments
    @assignments ||= volunteer.assignments
  end

  def admin_assignments
    @admin_assignments ||= assignments.where(admin: true)
  end

  def admin_region_ids
    admin_assignments.pluck(:region_id)
  end
end
