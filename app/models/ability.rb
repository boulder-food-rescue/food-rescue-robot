class Ability
  include CanCan::Ability

  def initialize(volunteer)
    @volunteer = volunteer

    super_admin_permissions if super_admin?
  end

  private

  attr_reader :volunteer

  def super_admin?
    volunteer.admin?
  end

  def super_admin_permissions
    can :manage, :all
  end
end
