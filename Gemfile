source 'https://rubygems.org'

# the base rails libraries
gem 'rails', '~> 3.2.13'

# for talking to the sqlite3 on-disk database
gem 'sqlite3'

# for handling json objects with ruby
gem 'json'

# Gems used only for assets and not required in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'therubyracer', :platforms => :ruby
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'uglifier', '>= 1.0.3'
end

# mobile-friendly template
gem 'twitter-bootstrap-rails'
gem 'rails_bootstrap_navbar'

# lets us use the ubiquitous jquery javascript library
gem 'jquery-rails', '2.1.4'

# dynamic in-place editing for some admin tables
gem 'active_scaffold'

# used to geo-locate locations
gem 'geocoder'

# handles authentication
gem 'devise'

# alternative webserver (>thin start)
gem 'thin'

# talk to the postgres database engine
gem 'pg'

# lets us post things to twitter programatically
gem 'twitter'

# This gem is for moving data easily between databases
# use rake db:data:dump to dump the data in your current db into a db/data.yaml
# use rake db:data:load to load the data in that file into your current db
gem 'yaml_db' 

# smart image attachment management
gem 'paperclip', '~> 3.1'

# generate pdfs
gem 'prawn'

# render google maps
gem 'gmaps4rails'

# lets us render charts in-browser
gem 'lazy_high_charts'

# To use debugger (dev only)
group :development do
  gem 'ruby-debug19'
end
