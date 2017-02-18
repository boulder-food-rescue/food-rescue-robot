require 'rails_helper'
require 'de_dup_log_volunteers'

RSpec.describe DeDupLogVolunteers do
  before :context do
    Log.destroy_all
    @log = FactoryGirl.create(:log)
    @log2 = FactoryGirl.create(:log)
    Volunteer.destroy_all
    @volunteer = FactoryGirl.create(:volunteer)
  end
  before :example do
    LogVolunteer.destroy_all
    LogVolunteer.create!(log_id: @log2.id, volunteer_id: @volunteer.id,
      active: true)
    begin
      dup = LogVolunteer.create!(log_id: @log2.id, volunteer_id: @volunteer.id,
        active: true)
      dup.destroy
    rescue ActiveRecord::StatementInvalid
      skip "duplicate log_volunteers with active = true are now prevented"
    end
    3.times do
      LogVolunteer.create(log_id: @log.id, volunteer_id: @volunteer.id,
        active: true)
    end
    LogVolunteer.create(log_id: @log.id, volunteer_id: @volunteer.id,
      active: false)
    @latest = LogVolunteer.create!(log_id: @log.id, volunteer_id: @volunteer.id,
      active: true)
    LogVolunteer.create(log_id: @log.id, volunteer_id: @volunteer.id,
      active: false)
  end
  it 'finds all active duplicates and sets all but one to inactive' do
    expect(LogVolunteer.count).to eq 7
    DeDupLogVolunteers.de_duplicate
    expect(LogVolunteer.count).to eq 7
    log1_r = LogVolunteer.where(log_id: @log.id)
    expect(log1_r.count).to eq 6
    log2_r = LogVolunteer.where(log_id: @log2.id)
    expect(log2_r.count).to eq 1
    active = LogVolunteer.where(log_id: @log.id, active: true)
    expect(active.count).to eq 1
  end
  it 'keeps the most recently updated duplicate' do
    DeDupLogVolunteers.de_duplicate
    active = LogVolunteer.where(log_id: @log.id, active: true).first
    expect(active.id).to eq @latest.id
  end
end
