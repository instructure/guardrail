module Shackles
  class << self
    def environment
      @environment ||= :master
    end

    def global_config
      @global_config ||= {}
    end

    # semi-private
    def initialize!
      require 'shackles/connection_handler'
      require 'shackles/connection_specification'

      ActiveRecord::ConnectionAdapters::ConnectionHandler.send(:include, ConnectionHandler)
      klass = Rails.version < '4' ? ActiveRecord::Base : ActiveRecord::ConnectionAdapters
      klass::ConnectionSpecification.send(:include, ConnectionSpecification)
    end

    def global_config_sequence
      @global_config_sequence ||= 1
    end

    def bump_sequence
      @global_config_sequence ||= 1
      @global_config_sequence += 1
      ActiveRecord::Base::connection_handler.clear_all_connections!
    end

    # for altering other pieces of config (i.e. username)
    # will force a disconnect
    def apply_config!(hash)
      global_config.merge!(hash)
      bump_sequence
    end

    def remove_config!(key)
      global_config.delete(key)
      bump_sequence
    end

    def connection_handlers
      save_handler
      @connection_handlers
    end

    # switch environment for the duration of the block
    # will keep the old connections around
    def activate(environment)
      environment ||= :master
      return yield if environment == self.environment
      begin
        old_environment = activate!(environment)
        yield
      ensure
        @environment = old_environment
        ActiveRecord::Base.connection_handler = ensure_handler unless Rails.env.test?
      end
    end

    # for use from script/console ONLY
    def activate!(environment)
      environment ||= :master
      save_handler
      old_environment = self.environment
      @environment = environment
      ActiveRecord::Base.connection_handler = ensure_handler unless Rails.env.test?
      old_environment
    end

    private
    def save_handler
      @connection_handlers ||= {}
      @connection_handlers[environment] ||= ActiveRecord::Base.connection_handler
    end

    def ensure_handler
      new_handler = @connection_handlers[environment]
      if !new_handler
        new_handler = @connection_handlers[environment] = ActiveRecord::ConnectionAdapters::ConnectionHandler.new
        pools = if Rails.version < '3.0'
                  ActiveRecord::Base.connection_handler.instance_variable_get(:@connection_pools)
                elsif Rails.version < '4.0'
                  ActiveRecord::Base.connection_handler.instance_variable_get(:@class_to_pool)
                else
                  ActiveRecord::Base.connection_handler.send(:owner_to_pool)
                end
        pools.each_pair do |model, pool|
          model = model.constantize if Rails.version >= '4'
          new_handler.establish_connection(model, pool.spec)
        end
      end
      new_handler
    end
  end
end

if defined?(Rails::Railtie)
  require "shackles/railtie"
else
  # just load everything immediately for Rails 2
  Shackles.initialize!
end
