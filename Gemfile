source 'https://rubygems.org'
ruby '2.1.5'

# the base rails libraries
gem 'rails', '~> 3.2.16'
gem 'thin'
gem 'pg'
gem 'rails_12factor'

# for handling json objects with ruby
gem 'json'

# lets us use the ubiquitous jquery javascript library
gem 'jquery-rails', '2.1.4'
gem 'sass-rails', '~> 3.2.6'
gem 'coffee-rails', '~> 3.2.1'
gem 'therubyracer', :platforms => :ruby
gem 'uglifier', '>= 1.0.3'
gem 'font-awesome-sass', '~> 4.4.0'
gem 'bootstrap-sass', '~> 3.2.0'
gem 'twitter-bootstrap-rails'
gem 'simple_form'

group :development do
  gem 'better_errors'
  gem 'rails-erd'
  gem 'binding_of_caller'
end

group :development, :test do
  gem 'sqlite3' # REMOVE THIS WHEN POSSIBLE
  gem 'pry-rails'
  gem 'pry-rescue'
  gem 'pry-remote'
  gem 'pry-byebug'
  gem 'awesome_print'
end

group :test do
  gem 'rspec-rails', '~> 3.5'
  gem 'factory_girl_rails'
  gem 'capybara'
  gem 'poltergeist', '~> 1.12'
  gem 'rack-test'
  gem 'test-unit', '~> 3.0'
end

# dynamic in-place editing for some admin tables
gem 'active_scaffold'

# handles authentication
gem 'devise', '~> 3.2.0'

# lets us post things to twitter programatically
gem 'twitter'
gem 'yaml_db'

# smart image attachment management
gem 'paperclip', git: 'https://github.com/thoughtbot/paperclip', ref: '523bd46c768226893f23889079a7aa9c73b57d68'
gem 'aws-sdk', '~> 2.3'

# generate pdfs
gem 'prawn', '~> 2.1.0'
gem 'prawn-table', '~> 0.2.2'

# used to geo-locate locations
gem 'geocoder'
gem 'gmaps4rails', '1.5.6'
gem 'addressable'

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

gem 'interactor'
gem 'cancancan'
