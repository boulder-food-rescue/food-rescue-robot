# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'spec_helper'
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'capybara/rails'
require 'capybara/rspec'
require 'capybara/poltergeist'
require 'devise'

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

Capybara.javascript_driver = :poltergeist
Warden.test_mode!

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!

  config.include Devise::TestHelpers, type: :controller

  config.include Warden::Test::Helpers, type: :feature
  config.include LoginHelpers,          type: :feature

  config.after(:each) do
    Warden.test_reset!
  end

  config.include FactoryGirl::Syntax::Methods

  config.include ActionDispatch::TestProcess

  def app
    Rails.application
  end
end
