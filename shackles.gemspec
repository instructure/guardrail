$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "shackles/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "shackles"
  s.version     = Shackles::VERSION
  s.authors     = ["Cody Cutrer"]
  s.email       = "cody@instructure.com"
  s.homepage    = "http://github.com/instructure/shackles"
  s.summary     = "ActiveRecord database environment switching for secondaries and least-privilege"
  s.description = "Allows multiple environments in database.yml, and dynamically switching them."
  s.license     = "MIT"

  s.files = Dir["lib/**/*"] + ["LICENSE", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.required_ruby_version = '>= 2.5'

  s.add_dependency "activerecord", ">= 5.1", "< 6.1"
  s.add_dependency "railties", ">= 5.1", "< 6.1"

  s.add_development_dependency "appraisal"
  s.add_development_dependency "byebug"
  s.add_development_dependency "mocha"
  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "sqlite3"
end
