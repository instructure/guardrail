# frozen_string_literal: true

module GuardRail
  module HelperMethods
    def self.included(base)
      base.singleton_class.include(ClassMethods)
      # call guard_rail_class_method on the class itself, which then calls guard_rail_method on the singleton_class
      base.singleton_class.singleton_class.include(ClassMethods)
    end

    # see readme for example usage
    module ClassMethods
      def guard_rail_class_methods(*methods, opts)
        methods.each { |m| guard_rail_class_method(m, opts) }
      end

      def guard_rail_class_method(method, opts)
        self.singleton_class.guard_rail_method(method, opts)
      end

      def guard_rail_methods(*methods, opts)
        methods.each { |m| guard_rail_method(m, opts) }
      end

      def guard_rail_method(method, opts)
        @guard_rail_module ||= begin
          m = Module.new
          self.prepend m
          m
        end

        @guard_rail_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
         def #{method}(*args)
           GuardRail.activate(#{opts[:environment].inspect}) { super }
         end
        RUBY
      end
    end
  end
end
