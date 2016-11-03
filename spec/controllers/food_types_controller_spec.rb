require 'rails_helper'

RSpec.describe FoodTypesController do
  let(:volunteer) { create :volunteer_with_assignment }

  it_behaves_like 'an authenticated indexable resource'
end
