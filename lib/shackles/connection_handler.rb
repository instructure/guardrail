module Shackles
  module ConnectionHandler
    %w{clear_active_connections clear_reloadable_connections
       clear_all_connections verify_active_connections }.each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}!(super_method: false)
          return super() if super_method
          ::Shackles.connection_handlers.values.each { |handler| handler.#{method}!(super_method: true) }
        end
      RUBY
    end
  end
end
