source 'https://rubygems.org/'
gemspec

if ENV['RAILS'] == '2'
  gem 'activerecord', '~> 2.3.18'
  gem 'rails', '~> 2.3.18', require: 'railties/initializer'
  gem 'i18n'
elsif ENV['RAILS'] == '3'
  gem 'activerecord', '~> 3.2.17'
  gem 'railties', '~> 3.2.17'
elsif ENV['RAILS'] == '4.0'
  gem 'activerecord', '~> 4.0.4'
  gem 'railties', '~> 4.0.4'
else
  gem 'activerecord', '~> 4.1.0'
  gem 'railties', '~> 4.1.0'
end
if ENV['RAILS'] == '2'
  gem "rspec", "~> 1.0"
else
  gem "rspec-core", "~> 2.0"
  gem "rspec-expectations", "~> 2.0"
end
gem 'mocha', :require => false