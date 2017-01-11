class RegionPolicy < ApplicationPolicy
  def index?
    super_admin?
  end

  def create?
    super_admin?
  end

  def update?
    super_admin? || region_admin_of?(record.id)
  end

  def destroy?
    super_admin?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
