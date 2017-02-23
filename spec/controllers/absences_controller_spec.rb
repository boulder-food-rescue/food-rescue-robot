require 'rails_helper'

RSpec.describe AbsencesController do
  let(:volunteer_with_assignment) { create :volunteer_with_assignment }

  it_behaves_like 'an authenticated indexable resource'

end
