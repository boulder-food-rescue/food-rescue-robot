class ScaleTypePolicy < ApplicationPolicy
  def index?
    super_admin? || region_admin?
  end

  def create?
    super_admin? || region_admin_of?(record.region_id)
  end

  def update?
    super_admin? || region_admin_of?(record.region_id)
  end

  def destroy?
    super_admin? || region_admin_of?(record.region_id)
  end

  class Scope < Scope
    def resolve
      if volunteer.admin?
        scope.all
      else
        scope.where(region_id: admin_region_ids)
      end
    end

    private

    def admin_region_ids
      volunteer.assignments.where(admin: true).pluck(:region_id)
    end
  end
end
