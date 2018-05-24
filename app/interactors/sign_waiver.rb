# frozen_string_literal: true

class SignWaiver
  include Interactor

  delegate :volunteer,
           :signed_at,
           :fail!,
           to: :context

  def call
    volunteer.waiver_signed    = true
    volunteer.waiver_signed_at = signed_at

    fail! unless volunteer.save
  end
end
