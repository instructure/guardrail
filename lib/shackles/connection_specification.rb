require 'i18n/core_ext/hash' unless Hash.method_defined?(:deep_symbolize_keys)

module Shackles
  module ConnectionSpecification
    class CacheCoherentHash < Hash
      def initialize(spec)
        @spec = spec
        super
      end

      def []=(key, value)
        super
        @spec.instance_variable_set(:@current_config, nil)
        @spec.instance_variable_get(:@config)[key] = value
      end

      def delete(key)
        super
        @spec.instance_variable_set(:@current_config, nil)
        @spec.instance_variable_get(:@config).delete(key)
      end

      def dup
        Hash[self]
      end
    end

    def self.included(klass)
      klass.send(:remove_method, :config)
      klass.alias_method_chain :initialize, :deep_symbolize
    end

    def initialize_with_deep_symbolize(config, adapter_method)
      initialize_without_deep_symbolize(config.deep_symbolize_keys, adapter_method)
    end

    def config
      @current_config = nil if Shackles.environment != @current_config_environment || Shackles.global_config_sequence != @current_config_sequence
      return @current_config if @current_config

      @current_config_environment = Shackles.environment
      @current_config_sequence = Shackles.global_config_sequence
      config = @config.dup
      if @config.has_key?(Shackles.environment)
        env_config = @config[Shackles.environment]
        # an array of databases for this environment; for now, just choose the first non-nil element
        if env_config.is_a?(Array)
          env_config = env_config.detect { |individual_config| !individual_config.nil? }
        end
        config.merge!(env_config.symbolize_keys)
      end

      config.keys.each do |key|
        next unless config[key].is_a?(String)
        config[key] = config[key] % config
      end

      config.merge!(Shackles.global_config)

      @current_config = CacheCoherentHash.new(self)
      @current_config.replace(config)

      @current_config
    end

    def config=(value)
      @config = value
      @current_config = nil
    end
  end
end
