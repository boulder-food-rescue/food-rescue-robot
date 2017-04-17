require 'rails_helper'

RSpec.describe 'Scheduling an Absence' do

  # let(:admin) { create :volunteer_with_assignment, admin: true }
  let(:today) { Time.zone.today }
  let(:in_two_days) { Time.zone.today + 2 }
  let(:in_four_days) { Time.zone.today + 4 }
  let(:volunteer_with_assignment) { create :volunteer_with_assignment }

  let!(:chain_too_soon) { create(:schedule_chain, day_of_week: in_two_days.wday, detailed_date: today) }
  let!(:schedule_volunteer_too_soon) { create(:schedule_volunteer, schedule_chain: chain_too_soon, volunteer: volunteer_with_assignment) }
  let!(:recipient_too_soon) { create(:recipient_schedule, schedule_chain: chain_too_soon, position: 1) }
  let!(:donor_too_soon) { create(:donation_schedule, schedule_chain: chain_too_soon, position: 2) }
  let!(:log_too_soon) { create(:log, when: in_two_days, schedule_chain: chain_too_soon) }

  let!(:chain_ok) { create(:schedule_chain, day_of_week: in_four_days.wday, detailed_date: today) }
  let!(:schedule_volunteer_ok) { create(:schedule_volunteer, schedule_chain: chain_ok, volunteer: volunteer_with_assignment) }
  let!(:recipient_ok) { create(:recipient_schedule, schedule_chain: chain_ok, position: 1) }
  let!(:donor_ok) { create(:donation_schedule, schedule_chain: chain_ok, position: 2) }
  let!(:log_ok) { create(:log, when: in_four_days, schedule_chain: chain_ok) }

  let!(:filter_start_day) { (Time.zone.today).strftime('%e') }
  let!(:filter_start_month) { (Time.zone.today).strftime('%B') }
  let!(:filter_start_year) { (Time.zone.today).strftime('%Y') }

  let!(:filter_end_day) { (Time.zone.today + 30).strftime('%e') }
  let!(:filter_end_month) { (Time.zone.today + 30).strftime('%B') }
  let!(:filter_end_year) { (Time.zone.today + 30).strftime('%Y') }

  context 'non-admin user' do
    context 'WITH assignment' do
      it 'can schedule' do
        login volunteer_with_assignment

        visit new_absence_path

        select filter_end_month, from: 'absence[stop_date(2i)]'
        select filter_end_day, from: 'absence[stop_date(3i)]'
        select filter_end_year, from: 'absence[stop_date(1i)]'


        click_on 'Save changes'

        binding.pry
save_and_open_page

        expect(current_path).to eq(absences_path)
        within('.alert') do
          expect(page).to have_content('No shifts of yours was found in that timeframe')
        end
      end
    end
  end
end
