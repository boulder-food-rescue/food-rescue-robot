require 'rails_helper'
require 'de_dup_log_volunteers'

RSpec.describe DeDupLogVolunteers do
  before :context do
    Log.destroy_all
    @log = FactoryGirl.create(:log)
    Volunteer.destroy_all
    @volunteer = FactoryGirl.create(:volunteer)
  end
  before :example do
    LogVolunteer.destroy_all
    @log2 = FactoryGirl.create(:log)
    LogVolunteer.create!(log_id: @log2.id, volunteer_id: @volunteer.id)
    begin
      dup = LogVolunteer.create!(log_id: @log2.id, volunteer_id: @volunteer.id)
      dup.destroy
    rescue ActiveRecord::StatementInvalid
      skip # duplicates are no longer allowed
    end
  end
  it 'removes duplicates' do
    LogVolunteer.create!(log_id: @log.id, volunteer_id: @volunteer.id)
    LogVolunteer.create!(log_id: @log.id, volunteer_id: @volunteer.id)
    LogVolunteer.create!(log_id: @log.id, volunteer_id: @volunteer.id)
    LogVolunteer.create!(log_id: @log.id, volunteer_id: @volunteer.id)
    expect(LogVolunteer.count).to eq 5

    DeDupLogVolunteers.de_duplicate

    expect(LogVolunteer.count).to eq 2
    log1_r = LogVolunteer.where(log_id: @log.id)
    expect(log1_r.count).to eq 1
    log2_r = LogVolunteer.where(log_id: @log2.id)
    expect(log2_r.count).to eq 1
  end
  it 'captures covering true' do
    LogVolunteer.create!(log_id: @log.id, volunteer_id: @volunteer.id,
      active: true, covering: false)
    LogVolunteer.create!(log_id: @log.id, volunteer_id: @volunteer.id,
      active: false, covering: false)
    LogVolunteer.create!(log_id: @log.id, volunteer_id: @volunteer.id,
      active: true, covering: true)

    DeDupLogVolunteers.de_duplicate

    log1_r = LogVolunteer.where(log_id: @log.id)
    expect(log1_r.count).to eq 1
    expect(log1_r.first.covering).to be true
  end
  it 'captures covering false' do
    LogVolunteer.create!(log_id: @log.id, volunteer_id: @volunteer.id,
      active: true, covering: false)
    LogVolunteer.create!(log_id: @log.id, volunteer_id: @volunteer.id,
      active: false, covering: false)

    DeDupLogVolunteers.de_duplicate

    log1_r = LogVolunteer.where(log_id: @log.id)
    expect(log1_r.count).to eq 1
    expect(log1_r.first.covering).to be false
  end
  it 'captures active true' do
    LogVolunteer.create!(log_id: @log.id, volunteer_id: @volunteer.id,
      active: false, covering: true)
    LogVolunteer.create!(log_id: @log.id, volunteer_id: @volunteer.id,
      active: false, covering: false)
    LogVolunteer.create!(log_id: @log.id, volunteer_id: @volunteer.id,
      active: true, covering: true)

    DeDupLogVolunteers.de_duplicate

    log1_r = LogVolunteer.where(log_id: @log.id)
    expect(log1_r.count).to eq 1
    expect(log1_r.first.active).to be true
  end
  it 'captures active false' do
    LogVolunteer.create!(log_id: @log.id, volunteer_id: @volunteer.id,
      active: false, covering: true)
    LogVolunteer.create!(log_id: @log.id, volunteer_id: @volunteer.id,
      active: false, covering: false)

    DeDupLogVolunteers.de_duplicate

    log1_r = LogVolunteer.where(log_id: @log.id)
    expect(log1_r.count).to eq 1
    expect(log1_r.first.active).to be false
  end
end
