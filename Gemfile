source 'https://rubygems.org'

ruby File.read('.ruby-version').strip

# the base rails libraries
gem 'pg'
gem 'rails', '~> 3.2.16'
gem 'rails_12factor'
gem 'thin'

# for handling json objects with ruby
gem 'json'

gem 'bootstrap-sass', '~> 3.2.0'
gem 'coffee-rails', '~> 3.2.1'
gem 'font-awesome-sass', '~> 4.4.0'
gem 'jquery-rails', '2.1.4'
gem 'sass-rails', '~> 3.2.6'
gem 'simple_form'
gem 'therubyracer', platforms: :ruby
gem 'twitter-bootstrap-rails'
gem 'uglifier', '>= 1.0.3'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'faker', '~> 1.7.3'
  gem 'rails-erd'
  gem 'rubocop', require: false
  gem 'rb-fsevent', '~> 0.9.0', require: false # latest 0.10.x seems to be incompatible with listen gem
  gem 'guard-rspec', require: false
end

group :development, :test do
  gem 'awesome_print'
  gem 'dotenv-rails'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'pry-remote'
  gem 'pry-rescue'
  gem 'sqlite3' # REMOVE THIS WHEN POSSIBLE
end

group :test do
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'factory_girl_rails'
  gem 'poltergeist', '~> 1.12'
  gem 'rack-test'
  gem 'rspec-rails', '~> 3.5'
end
# Temporary fix: https://stackoverflow.com/questions/13828889/rails-3-heroku-cannot-load-such-file-test-unit-testcase-loaderror
# Remove after upgrade of Rails from 3.2 is complete.
gem 'test-unit', '~> 3.0'

# dynamic in-place editing for some admin tables
gem 'active_scaffold'

# handles authentication
gem 'devise', '~> 3.2.0'

# lets us post things to twitter programatically
gem 'twitter'
gem 'yaml_db'

# smart image attachment management
gem 'aws-sdk', '~> 2.3'
gem 'paperclip', git: 'https://github.com/thoughtbot/paperclip',
                 ref: '523bd46c768226893f23889079a7aa9c73b57d68'

# generate pdfs
gem 'prawn', '~> 2.1.0'
gem 'prawn-table', '~> 0.2.2'

# used to geo-locate locations
gem 'addressable'
gem 'geocoder'
gem 'gmaps4rails', '1.5.6'

# lets us render charts in-browser
gem 'highcharts-rails', '~> 3.0.0'

# gives us pretty data tables
gem 'jquery-datatables-rails', git: 'https://github.com/rweng/jquery-datatables-rails.git'

# nested selecitons of volunteers on schedules
gem 'cocoon'

# set timezone to browser timezone
gem 'browser-timezone-rails'#, '~> 0.0.9'
gem 'ranked-model'

#Send email when exception occurs.
gem 'exception_notification', '~> 3.0.1'
gem 'exception_notification-rake', '~> 0.0.6'

gem 'cancancan'
gem 'interactor'
gem 'newrelic_rpm'
