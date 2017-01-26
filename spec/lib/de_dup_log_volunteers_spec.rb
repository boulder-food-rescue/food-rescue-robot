require 'rails_helper'
require 'de_dup_log_volunteers'

RSpec.describe DeDupLogVolunteers do
  it 'removes duplicates' do
    log = FactoryGirl.create(:log)
    volunteer = FactoryGirl.create(:volunteer)
    LogVolunteer.create!(log_id: log.id, volunteer_id: volunteer.id)
    LogVolunteer.create!(log_id: log.id, volunteer_id: volunteer.id)
    LogVolunteer.create!(log_id: log.id, volunteer_id: volunteer.id)
    log2 = FactoryGirl.create(:log)
    LogVolunteer.create!(log_id: log2.id, volunteer_id: volunteer.id)
    expect(LogVolunteer.count).to eq 4

    DeDupLogVolunteers.de_duplicate

    expect(LogVolunteer.count).to eq 2
    log1_r = LogVolunteer.where(log_id: log.id)
    expect(log1_r.count).to eq 1
    log2_r = LogVolunteer.where(log_id: log2.id)
    expect(log2_r.count).to eq 1
  end
end
