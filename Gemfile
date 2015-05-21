source 'http://rubygems.org'

gem 'rails', '3.0.1'
gem 'authlogic', '~> 3.0'
gem 'formtastic', '2.3.1'
gem 'cancan', '1.6.8'
gem 'will_paginate', '~> 3.0'
gem 'rake', '0.9.2.2'
gem 'test-unit', '1.2.3'
gem 'cells', '3.5.6'
gem 'meta_search', '0.5.0'
group :production, :development do
  gem 'activerecord-postgresql-adapter'
  gem 'pg', '0.17.1'
end
group :development, :test do
  gem 'sqlite3'
  #gem "rspec", "= 1.2.9"
  gem "rspec-rails", "~> 2.0"
  gem 'factory_girl', '= 2.6.4', :require => false
  gem 'database_cleaner'
end
#gem 'prototype-rails'
gem 'dynamic_form'  # Rails 2 compatibility
