# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LogVolunteer do
  let(:log_id) { 100 }
  let(:volunteer_id) { 200 }

  it 'prevents active duplicate records' do
    LogVolunteer.create!(log_id: log_id, volunteer_id: volunteer_id, active: true)

    expect do
      LogVolunteer.create!(log_id: log_id, volunteer_id: volunteer_id, active: true)
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'allows inactive duplicate records' do
    LogVolunteer.create!(log_id: log_id, volunteer_id: volunteer_id, active: true)

    expect do
      LogVolunteer.create!(log_id: log_id, volunteer_id: volunteer_id, active: false)
      LogVolunteer.create!(log_id: log_id, volunteer_id: volunteer_id, active: false)
    end.not_to raise_error
  end
end
