class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def scope
    Pundit.policy_scope!(volunteer, record.class)
  end

  private

  alias_method :volunteer, :user

  def super_admin?
    volunteer.admin?
  end

  def region_admin?
    !volunteer.assignments.where(admin: true).empty?
  end

  def admin_region_ids
    volunteer.assignments.where(admin: true).pluck(:region_id)
  end

  def region_admin_of?(*region_ids)
    (region_ids - admin_region_ids).empty?
  end

  class Scope
    attr_reader :volunteer, :scope

    def initialize(volunteer, scope)
      @volunteer = volunteer
      @scope = scope
    end

    def resolve
      scope.where('false')
    end
  end
end
