source 'http://rubygems.org'

gem 'rails', '2.3.18'
gem 'authlogic', '2.1.3'
gem 'formtastic', '0.9.7'
gem 'cancan', '1.3.4'
gem 'searchlogic', '2.4.14'
gem 'will_paginate', '2.3.12'
gem 'rake', '0.9.2.2'
gem 'test-unit', '1.2.3'
group :production, :development do
  gem 'activerecord-postgresql-adapter'
  gem 'pg', '0.17.1'
end
group :development, :test do
  gem 'sqlite3'
  #gem "rspec", "= 1.2.9"
  gem "rspec-rails", "= 1.2.9"
  gem 'factory_girl', '= 2.6.4', :require => false
  gem 'database_cleaner'
end
