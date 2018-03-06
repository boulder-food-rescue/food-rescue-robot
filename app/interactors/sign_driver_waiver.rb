class SignDriverWaiver
  include Interactor

  delegate :volunteer,
           :signed_at,
           :fail!,
           to: :context

  def call
    volunteer.driver_waiver_signed    = true
    volunteer.driver_waiver_signed_at = signed_at

    fail! unless volunteer.save
  end
end
