module Shackles
  module ConnectionSpecification
    class CacheCoherentHash < Hash
      def initialize(spec)
        @spec = spec
        super
      end

      def []=(key, value)
        @spec.instance_variable_set(:@current_config, nil)
        @spec.instance_variable_get(:@config)[key] = value
      end

      def delete(key)
        @spec.instance_variable_set(:@current_config, nil)
        @spec.instance_variable_get(:@config).delete(key)
      end
    end

    def self.included(klass)
      klass.send(:remove_method, :config)
    end

    def config
      @current_config = nil if Shackles.environment != @current_config_environment || Shackles.global_config_sequence != @current_config_sequence
      return @current_config if @current_config

      @current_config_environment = Shackles.environment
      @current_config_sequence = Shackles.global_config_sequence
      config = @config.dup
      if @config.has_key?(Shackles.environment)
        config.merge!(@config[Shackles.environment].symbolize_keys)
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
