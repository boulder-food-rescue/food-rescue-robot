require 'rails_helper'

RSpec.describe FoodRobot do
  let(:monday) { Time.zone.today.monday }
  let(:tuesday) { monday + 1.day }

  describe '::generate_log_entries' do
    context 'without an absence' do
      context 'with an irregular schedule chain' do
        let!(:chain) { create(:schedule_chain, day_of_week: monday.wday, irregular: true) }
        let!(:donor) { create(:donation_schedule, schedule_chain: chain, position: 1) }
        let!(:recipient) { create(:recipient_schedule, schedule_chain: chain, position: 2) }

        subject { described_class.generate_log_entries(monday) }

        it 'generates no logs' do
          expect { subject }.to change { Log.count }.by(0)
        end
      end

      context 'with a non-functional schedule chain' do
        let!(:chain) { create(:schedule_chain, day_of_week: monday.wday) }
        let!(:recipient) { create(:recipient_schedule, schedule_chain: chain, position: 1) }
        let!(:donor) { create(:donation_schedule, schedule_chain: chain, position: 2) }

        subject { described_class.generate_log_entries(monday) }

        it 'generates no logs' do
          expect { subject }.to change { Log.count }.by(0)
        end
      end

      context 'with a weekly schedule chain' do
        let!(:chain) { create(:schedule_chain, day_of_week: monday.wday, num_volunteers: 3) }
        let!(:donor1) { create(:donation_schedule, schedule_chain: chain, position: 1) }
        let!(:donor2) { create(:donation_schedule, schedule_chain: chain, position: 2) }
        let!(:recipient) { create(:recipient_schedule, schedule_chain: chain, position: 3) }

        context 'for a day other than the day of the schedule chain' do
          subject { described_class.generate_log_entries(tuesday) }

          it 'generates no logs' do
            expect { subject }.to change { Log.count }.by(0)
          end
        end

        context 'for the day of the schedule chain' do
          subject { described_class.generate_log_entries(monday) }

          it 'generates a log for each donor' do
            expect { subject }.to change { Log.count }.by(2)
          end

          it 'returns the number of created logs' do
            n, _ = subject
            expect(n).to eq(2)
          end

          it 'returns the number of skipped logs' do
            _, n_skipped = subject
            expect(n_skipped).to eq(0)
          end

          context 'with a log already generated' do
            before do
              create(
                :log,
                when: monday,
                schedule_chain: chain,
                donor: donor1.location,
                recipients: [recipient.location]
              )
            end

            it 'does not generate duplicate logs' do
              expect { subject }.to change { Log.count }.by(1)
            end

            it 'returns the number of created logs' do
              n, _ = subject
              expect(n).to eq(1)
            end

            it 'returns the number of skipped logs' do
              _, n_skipped = subject
              expect(n_skipped).to eq(1)
            end
          end
        end
      end

      context 'with a schedule chain ending at a hub' do
        let!(:chain) { create(:schedule_chain, day_of_week: monday.wday, num_volunteers: 3) }
        let!(:donor) { create(:donation_schedule, schedule_chain: chain, position: 1) }
        let!(:hub) { create(:schedule, schedule_chain: chain, location: create(:hub), position: 2) }

        subject { described_class.generate_log_entries(monday) }

        it 'does not generate a log for the hub' do
          expect { subject }.to change { Log.count }.by(1)
        end
      end

      describe 'created logs' do
        let!(:chain) do
          create(
            :schedule_chain,
            :one_time,
            detailed_date: monday,
            num_volunteers: 3
          )
        end

        # Volunteers
        let!(:schedule_volunteer1) { create(:schedule_volunteer, schedule_chain: chain) }
        let!(:schedule_volunteer2) { create(:schedule_volunteer, schedule_chain: chain) }

        # Schedules
        let!(:donor1) { create(:donation_schedule, schedule_chain: chain, position: 1) }
        let!(:recipient1) { create(:recipient_schedule, schedule_chain: chain, position: 2) }
        let!(:donor2) { create(:donation_schedule, schedule_chain: chain, position: 3) }
        let!(:recipient2) { create(:recipient_schedule, schedule_chain: chain, position: 4) }

        subject { Log.order(:created_at).last(2) }

        it 'are created for each donor' do
          described_class.generate_log_entries(monday)
          expect(subject.first.donor).to eq(donor1.location)
          expect(subject.second.donor).to eq(donor2.location)
        end

        it 'reference each recipient following the donor in the chain' do
          described_class.generate_log_entries(monday)
          expect(subject.first.recipients).to match_array([recipient1, recipient2].map(&:location))
          expect(subject.second.recipients).to contain_exactly(recipient2.location)
        end

        it 'are assigned the correct date' do
          described_class.generate_log_entries(monday)
          expect(subject.first.when).to eq(monday)
          expect(subject.second.when).to eq(monday)
        end

        it 'are assigned the correct schedule chain' do
          described_class.generate_log_entries(monday)
          expect(subject.first.schedule_chain).to eq(chain)
          expect(subject.second.schedule_chain).to eq(chain)
        end

        it 'are assigned the region from the schedule chain' do
          described_class.generate_log_entries(monday)
          expect(subject.first.region).to eq(chain.region)
          expect(subject.second.region).to eq(chain.region)
        end

        it 'are assigned a number of volunteers from the schedule chain' do
          described_class.generate_log_entries(monday)
          expect(subject.first.num_volunteers).to eq(chain.num_volunteers)
          expect(subject.second.num_volunteers).to eq(chain.num_volunteers)
        end

        it 'are assigned the volunteers from the schedule chain' do
          described_class.generate_log_entries(monday)
          volunteers = [schedule_volunteer1, schedule_volunteer2].map(&:volunteer)
          expect(subject.first.volunteers).to match_array(volunteers)
          expect(subject.second.volunteers).to match_array(volunteers)
        end

        describe 'log parts' do
          let!(:donor1_part1) { create(:schedule_part, schedule: donor1, required: true) }
          let!(:donor1_part2) { create(:schedule_part, schedule: donor1, required: false) }
          let!(:recipient1_part1) { create(:schedule_part, schedule: recipient1, required: true) }
          let!(:recipient1_part2) { create(:schedule_part, schedule: recipient1, required: false) }
          let!(:donor2_part1) { create(:schedule_part, schedule: donor2, required: true) }
          let!(:donor2_part2) { create(:schedule_part, schedule: donor2, required: false) }
          let!(:recipient2_part1) { create(:schedule_part, schedule: recipient2, required: true) }
          let!(:recipient2_part2) { create(:schedule_part, schedule: recipient2, required: false) }

          it 'are assigned from the donors in the schedule chain' do
            described_class.generate_log_entries(monday)

            expect(subject.first.log_parts.length).to eq(2)
            expect(subject.first.log_parts.first.food_type).to eq(donor1_part1.food_type)
            expect(subject.first.log_parts.first.required).to eq(donor1_part1.required)
            expect(subject.first.log_parts.last.food_type).to eq(donor1_part2.food_type)
            expect(subject.first.log_parts.last.required).to eq(donor1_part2.required)

            expect(subject.second.log_parts.length).to eq(2)
            expect(subject.second.log_parts.first.food_type).to eq(donor2_part1.food_type)
            expect(subject.second.log_parts.first.required).to eq(donor2_part1.required)
            expect(subject.second.log_parts.last.food_type).to eq(donor2_part2.food_type)
            expect(subject.second.log_parts.last.required).to eq(donor2_part2.required)
          end
        end
      end
    end

    context 'with an absence' do
      let!(:absence) { create(:absence) }
      let(:volunteer) { absence.volunteer }

      context 'with no schedule chains belonging to the volunteer scheduling the absence' do
        let!(:chain) { create(:schedule_chain, day_of_week: monday.wday) }
        let!(:donor) { create(:donation_schedule, schedule_chain: chain, position: 1) }
        let!(:recipient) { create(:recipient_schedule, schedule_chain: chain, position: 2) }

        subject { described_class.generate_log_entries(monday, absence) }

        it 'generates no logs' do
          expect { subject }.to change { Log.count }.by(0)
        end
      end

      context 'with a schedule chain belonging to the volunteer scheduling the absence' do
        let!(:chain) { create(:schedule_chain, volunteers: [volunteer], day_of_week: monday.wday) }
        let!(:donor1) { create(:donation_schedule, schedule_chain: chain, position: 1) }
        let!(:donor2) { create(:donation_schedule, schedule_chain: chain, position: 2) }
        let!(:recipient) { create(:recipient_schedule, schedule_chain: chain, position: 3) }

        subject { described_class.generate_log_entries(monday, absence) }

        it 'generates a log for each donor' do
          expect { subject }.to change { Log.count }.by(2)
        end

        it 'returns the number of created logs' do
          n, _ = subject
          expect(n).to eq(2)
        end

        it 'returns the number of skipped logs' do
          _, n_skipped = subject
          expect(n_skipped).to eq(0)
        end

        context 'with a log already generated' do
          let!(:log) do
            create(
              :log,
              when: monday,
              schedule_chain: chain,
              donor: donor1.location,
              recipients: [recipient.location],
              volunteers: [volunteer]
            )
          end

          it 'does not generate duplicate logs' do
            expect { subject }.to change { Log.count }.by(1)
          end

          it 'removes the volunteer from the pre-existing log' do
            subject
            expect(log.reload.volunteers).not_to include(volunteer)
          end

          it 'adds the absence to the pre-existing log' do
            subject
            expect(log.reload.absences).to include(absence)
          end

          it 'returns the number of created/modified logs' do
            n, _ = subject
            expect(n).to eq(2)
          end

          it 'returns the number of skipped logs' do
            _, n_skipped = subject
            expect(n_skipped).to eq(0)
          end
        end
      end

      describe 'created log' do
        let!(:chain) { create(:schedule_chain, :one_time, detailed_date: monday, volunteers: [volunteer]) }

        let!(:donor) { create(:donation_schedule, schedule_chain: chain, position: 1) }
        let!(:recipient) { create(:recipient_schedule, schedule_chain: chain, position: 2) }

        subject { Log.order(:created_at).last }

        it 'references the provided absence' do
          described_class.generate_log_entries(monday, absence)
          expect(subject.absences).to include(absence)
        end

        it 'is not assigned the volunteer scheduling the absence' do
          described_class.generate_log_entries(monday, absence)
          expect(subject.volunteers).not_to include(volunteer)
        end
      end
    end
  end
end
