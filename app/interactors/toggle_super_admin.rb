class ToggleSuperAdmin
  include Interactor

  delegate :volunteer,
           :fail!,
           to: :context

  def call
    volunteer.admin = !volunteer.admin
    fail! unless volunteer.save
  end
end
