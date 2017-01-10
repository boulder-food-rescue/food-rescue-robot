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
