# frozen_string_literal: true

class ReactivateVolunteer
  include Interactor

  delegate :volunteer,
           :fail!,
           to: :context

  def call
    fail! unless volunteer.update_attribute(:active, true)
  end
end
