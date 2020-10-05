GuardRail
==========

## About

GuardRail allows multiple database environments and environment overrides to
ActiveRecord, allowing least-privilege best practices.

## Installation

Add `gem 'guardrail'` to your Gemfile (tested with Rails 4.x and 5.x, and also
with the release candidate for Rails 6.0)

## Usage

There are two major use cases for guardrail. The first is for primary/replica(/deploy) environments.
Using a replica is as simple as adding a replica block (underneath your main environment block) in
database.yml, then wrapping stuff you want to query the replica in GuardRail.activate(:replica) blocks.
You can extend this to a deploy environment so that migrations will run as a deploy user that
permission to modify schema, while your normal app runs with lower privileges that cannot modify
schema. This is defense-in-depth in practice, so that *if* you happen to have a SQL injection
bug, it would be impossible to do something like dropping tables.

The other major use case is more defense-in-depth. By carefully setting up your environment, you
can default to script/console sessions for regular users to use their own database user, and the
replica.

Example database.yml file:

```yaml
production:
  adapter: postgresql
  username: myapp
  database: myapp
  host: db-primary
  replica:
    host: db-replica
  deploy:
    username: deploy
```

Using an initializer, you can achieve the default environment settings (in tandem with profile
changes):

```ruby
if ENV['RAILS_DATABASE_ENVIRONMENT']
  GuardRail.activate!(ENV['RAILS_DATABASE_ENVIRONMENT'].to_sym)
end
if ENV['RAILS_DATABASE_USER']
  GuardRail.apply_config!(:username => ENV['RAILS_DATABASE_USER'])
end
```

Additionally **in Ruby 2.0+** you can include GuardRail::HelperMethods and use several helpers
to execute methods on specific environments:

```ruby
class SomeModel
  include GuardRail::HelperMethods

  def expensive_read_only
    ...
  end
  guard_rail_method :expensive_read_only, environment: :replica

  def self.class_level_expensive_read_only
    ...
  end
  gaurd_rail_class_method :class_level_expensive_read_only, environment: :replica

  # helpers for multiple methods are also available

  guard_rail_methods :instance_method_foo, :instance_method_bar, environment: :replica
  guard_rail_class_methods :class_method_foo, :class_method_bar, environment: :replica
end
```
