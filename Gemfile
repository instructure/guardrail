source 'https://rubygems.org/'
gemspec

if ENV['RAILS'] == '2'
  gem 'activerecord', '~> 2.3'
  gem 'rails', '~> 2.3', require: 'railties/initializer'
  gem 'i18n'
elsif ENV['RAILS'] == '3'
  gem 'activerecord', '~> 3.2'
  gem 'railties', '~> 3.2'
else
  gem 'activerecord', '~> 4.0'
  gem 'railties', '~> 4.0'
end
if ENV['RAILS'] == '2'
  gem "rspec", "~> 1"
else
  gem "rspec-core", "~> 2"
  gem "rspec-expectations", "~> 2"
end
gem 'mocha', :require => false