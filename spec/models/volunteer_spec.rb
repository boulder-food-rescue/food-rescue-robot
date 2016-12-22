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
end
