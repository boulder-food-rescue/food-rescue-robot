require 'rails_helper'

RSpec.describe 'Scheduling an Absence' do

  let(:volunteer_with_assignment) { create :volunteer_with_assignment }
  let(:volunteer_without_assignment) { create :volunteer_with_region }
  let(:admin) { create :volunteer_with_assignment, admin: true }

    context 'non-admin user' do
      context 'WITHOUT assignment' do
        it 'cannot schedule' do
          login volunteer_without_assignment
          byebug

save_and_open_page

           within ".navbar" do
             within('ul:nth-child(1)') do
               within('li:nth-child(3)') do
                 within('ul:nth-child(1)') do
                   within('li:nth-child(4)') do
                     click_on 'Schedule An Absence'
                   end
                 end
               end
             end
           end
           
           expect(current_path).to eq(new_absence_path)

           click_on 'Save changes'

           expect(current_path).to eq(absences_path)
           within('.alert') do
            expect(page).to have_content('No shifts of yours was found in that timeframe')
           end
        end
      end
    end
end
