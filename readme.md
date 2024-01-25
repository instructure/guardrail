GuardRail
==========

## About

GuardRail is a thin wrapper around Rail 6.1's native role switching.

## Installation

Add `gem 'guardrail'` to your Gemfile.

## Usage

See https://guides.rubyonrails.org/active_record_multiple_databases.html. GuardRail simply adds
syntactic sugar to easily switch to different roles:


```ruby
def some_method
  GuardRails.activate(:secondary) do
    MyModel.some_really_long_query
  end
end
```

Additionally you can include GuardRail::HelperMethods and use several helpers
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
  guard_rail_class_method :class_level_expensive_read_only, environment: :replica

  # helpers for multiple methods are also available

  guard_rail_methods :instance_method_foo, :instance_method_bar, environment: :replica
  guard_rail_class_methods :class_method_foo, :class_method_bar, environment: :replica
end
```
