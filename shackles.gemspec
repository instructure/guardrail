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
  s.summary     = "ActiveRecord database environment switching for slaves and least-privilege"
  s.description = "Allows multiple environments in database.yml, and dynamically switching them."
  s.license     = "MIT"

  s.files = Dir["lib/**/*"] + ["LICENSE", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "activerecord", ">= 3.2", "< 4.2"
  s.add_development_dependency "mocha"
  s.add_development_dependency "sqlite3"
end
