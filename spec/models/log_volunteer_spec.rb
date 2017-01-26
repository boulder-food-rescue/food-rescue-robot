require 'rails_helper'

RSpec.describe LogVolunteer do
  it 'prevents duplicate records' do
    log = FactoryGirl.create(:log)
    volunteer = FactoryGirl.create(:volunteer)
    expect do
      lv = LogVolunteer.create!(log_id: log.id, volunteer_id: volunteer.id)
      lv = LogVolunteer.create!(log_id: log.id, volunteer_id: volunteer.id)
    end.to raise_error(ActiveRecord::StatementInvalid)
  end
end
