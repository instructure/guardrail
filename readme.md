Shackles
==========

## About

Shackles allows multiple database environments and environment overrides to
ActiveRecord, allowing least-privilege best practices.

## Installation

Add `gem 'shackles'` to your Gemfile (tested with Rails 2.3 and 3.2)

## Usage

There are two major use cases for shackles. The first is for master/slave(/deploy) environments.
Using a slave is as simple as adding a slave block (underneath your main environment block) in
database.yml, then wrapping stuff you want to query the slave in Shackles.activate(:slave) blocks.
You can extend this to a deploy environment so that migrations will run as a deploy user that
permission to modify schema, while your normal app runs with lower privileges that cannot modify
schema. This is defense-in-depth in practice, so that *if* you happen to have a SQL injection
bug, it would be impossible to do something like dropping tables.

The other major use case is more defense-in-depth. By carefully setting up your environment, you
can default to script/console sessions for regular users to use their own database user, and the
slave.

Example database.yml file:

```yaml
production:
  adapter: postgresql
  username: myapp
  database: myapp
  host: db-master
  slave:
    host: db-slave
  deploy:
    username: deploy
```

Using an initializer, you can achieve the default environment settings (in tandem with profile
changes):

```ruby
if ENV['RAILS_DATABASE_ENVIRONMENT']
  Shackles.activate!(ENV['RAILS_DATABASE_ENVIRONMENT'].to_sym)
end
if ENV['RAILS_DATABASE_USER']
  Shackles.apply_config!(:username => ENV['RAILS_DATABASE_USER'])
end
```
