class SignDriverWaiver
  include Interactor

  delegate :volunteer_signee,
           :signed_at,
           :fail!,
           :admin_signee,
           to: :context

  def call
    if admin_signee.blank?
      volunteer_signee.driver_waiver_signed    = true
      volunteer_signee.driver_waiver_signed_at = signed_at
    else
      volunteer_signee.driver_waiver_signed_by_admin_id = admin_signee.id
      volunteer_signee.driver_waiver_signed_by_admin_at = signed_at
    end

    fail! unless volunteer_signee.save
  end
end
