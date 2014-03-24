module Shackles
  module ConnectionHandler
    def self.included(klass)
      %w{clear_active_connections clear_reloadable_connections
         clear_all_connections verify_active_connections }.each do |method|
        next unless klass.instance_methods.include?("#{method}!".to_sym) # AR 4.0.3 no longer includes verify_active_connections!

        klass.class_eval(<<EOS)
          def #{method}_with_multiple_environments!
            ::Shackles.connection_handlers.values.each(&:#{method}_without_multiple_environments!)
          end
EOS
        klass.alias_method_chain "#{method}!".to_sym, :multiple_environments
      end
    end
  end
end
