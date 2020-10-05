require 'i18n/core_ext/hash' unless Hash.method_defined?(:deep_symbolize_keys)

module GuardRail
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

      # in rails 4.2, active support tries to create a copy of the original object's class
      # instead of making a new Hash object, so it fails since initialize expects an argument
      def transform_keys(&block)
        dup.transform_keys(&block)
      end
    end

    def initialize(name, config, adapter_method)
      super(name, config.deep_symbolize_keys, adapter_method)
    end

    def initialize_dup(original)
      @current_config = nil
      super
    end

    def config
      @current_config = nil if GuardRail.environment != @current_config_environment || GuardRail.global_config_sequence != @current_config_sequence
      return @current_config if @current_config

      @current_config_environment = GuardRail.environment
      @current_config_sequence = GuardRail.global_config_sequence
      config = @config.dup
      if @config.has_key?(GuardRail.environment)
        env_config = @config[GuardRail.environment]
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

      config.merge!(GuardRail.global_config)

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
