require 'rails_helper'

RSpec.describe Volunteer do
  let(:volunteer) { create(:volunteer) }

  describe '#unassigned?' do
    subject { volunteer }

    it 'returns true if the volunteer has no assignments' do
      subject.assignments.destroy_all
      expect(subject.unassigned?).to eq(true)
    end

    it 'returns false if the volunteer has any assignments' do
      create(:assignment, volunteer: subject)
      expect(subject.unassigned?).to eq(false)
    end
  end

  describe '#needs_training?' do
    subject { volunteer }

    context 'when the volunteer has no completed logs' do
      let(:log_volunteer) { create(:log_volunteer, volunteer: subject) }

      before do
        log_volunteer.log.complete = false
        log_volunteer.log.save!
      end

      it 'returns true' do
        expect(subject.needs_training?).to eq(true)
      end
    end

    context 'when the volunteer has a completed log' do
      let(:log_volunteer) { create(:log_volunteer, volunteer: subject) }

      before do
        log_volunteer.log.complete = true
        log_volunteer.log.hours_spent = 1
        log_volunteer.log.why_zero = Log::WhyZero.invert["No Food"]
        log_volunteer.log.save!
      end

      it 'returns false' do
        expect(subject.needs_training?).to eq(false)
      end
    end
  end

  describe '#current_absences' do
    subject { volunteer }
    let(:today) { Date.today }

    it 'includes absences that started before today and end after today' do
      current_absence = create(:absence, volunteer: subject, start_date: today - 1.day, stop_date: today + 1.day)

      expect(subject.current_absences).to contain_exactly(current_absence)
    end

    it 'excludes absences for other volunteers' do
      absence_for_other = create(
        :absence,
        start_date: today - 1.day,
        stop_date: today + 1.day
      )

      expect(subject.current_absences).not_to include(absence_for_other)
    end

    it 'excludes absences that start today' do
      absence_starting_today = create(
        :absence,
        volunteer: subject,
        start_date: today,
        stop_date: today + 3.days
      )

      expect(subject.current_absences).not_to include(absence_starting_today)
    end

    it 'excludes absences that start in the future' do
      future_absence = create(
        :absence,
        volunteer: subject,
        start_date: today + 1.day,
        stop_date: today + 3.days
      )

      expect(subject.current_absences).not_to include(future_absence)
    end

    it 'excludes absences that stopped in the past' do
      past_absence = create(
        :absence,
        volunteer: subject,
        start_date: today - 3.days,
        stop_date: today - 1.day
      )

      expect(subject.current_absences).not_to include(past_absence)
    end

    it 'excludes absences that stop today' do
      absence_stopping_today = create(
        :absence,
        volunteer: subject,
        start_date: today - 3.days,
        stop_date: today
      )

      expect(subject.current_absences).not_to include(absence_stopping_today)
    end
  end
end
