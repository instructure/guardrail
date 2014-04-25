module Shackles
  module ConnectionHandler
    def self.included(klass)
      %w{clear_active_connections clear_reloadable_connections
         clear_all_connections verify_active_connections }.each do |method|
        next unless klass.instance_methods.include?("#{method}!".to_sym)
        klass.class_eval(<<EOS, __FILE__, __LINE__ + 1)
          def #{method}_with_multiple_environments!
            ::Shackles.connection_handlers.values.each(&:#{method}_without_multiple_environments!)
          end
EOS
        klass.alias_method_chain "#{method}!".to_sym, :multiple_environments
      end
    end
  end
end
