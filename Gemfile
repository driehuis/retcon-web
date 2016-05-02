source 'http://rubygems.org'

gem 'rails', '~> 3.2.0'
gem 'authlogic', '3.2.0'
gem 'formtastic', '~> 2.0'
gem 'cancan', '1.6.8'
#gem 'will_paginate', '~> 3.0'
gem 'kaminari'
#gem 'rake', '0.9.2.2'
gem 'cells', '~> 3.8.0'
gem 'ransack'
group :assets do
  gem 'sass-rails',   '~> 3.2'
  gem 'coffee-rails', '~> 3.2'
  gem 'uglifier',     '>= 1.0.3'
end

# jQuery is the default JavaScript library in Rails 3.1
gem 'jquery-rails'
group :production, :development do
  gem 'activerecord-postgresql-adapter'
  gem 'pg', '0.17.1'
end
group :test do
  gem 'test-unit', '1.2.3'
end
group :development, :test do
  gem 'sqlite3'
  gem "rspec-rails", "~> 3.0"
  gem 'factory_girl_rails', "~> 3.0"
  gem 'database_cleaner'
  gem 'byebug'
end
#gem 'prototype-rails'
gem 'dynamic_form'  # Rails 2 compatibility
gem 'quiet_assets'
# Allow database dump and restore to YAML format.
gem 'yaml_db'
