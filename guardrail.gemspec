$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "guard_rail/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "guardrail"
  s.version     = GuardRail::VERSION
  s.authors     = ["Cody Cutrer"]
  s.email       = "cody@instructure.com"
  s.homepage    = "http://github.com/instructure/guardrail"
  s.summary     = "ActiveRecord database environment switching for secondaries and least-privilege"
  s.description = "Allows multiple environments in database.yml, and dynamically switching them."
  s.license     = "MIT"

  s.files = Dir["lib/**/*"] + ["LICENSE", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.required_ruby_version = '>= 3.2'

  s.add_dependency "activerecord", ">= 6.1", "< 8.1"
  s.add_dependency "railties", ">= 6.1", "< 8.1"

  s.add_development_dependency "debug"
end
