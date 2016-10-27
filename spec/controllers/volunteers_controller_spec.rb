require 'rails_helper'

RSpec.describe VolunteersController do
  let(:volunteer) { create :volunteer_with_assignment }
  let(:resource) { create :volunteer }

  it_behaves_like 'an authenticated indexable resource'
  it_behaves_like 'an authenticated showable resource'
end
