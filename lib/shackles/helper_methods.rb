module Shackles
  module HelperMethods
    def self.included(base)
      base.singleton_class.include(ClassMethods)
      # call shackle_class_method on the class itself, which then calls shackle_method on the singleton_class
      base.singleton_class.singleton_class.include(ClassMethods)
    end

    # see readme for example usage
    module ClassMethods
      def shackle_class_methods(*methods, opts)
        methods.each { |m| shackle_class_method(m, opts) }
      end

      def shackle_class_method(method, opts)
        self.singleton_class.shackle_method(method, opts)
      end

      def shackle_methods(*methods, opts)
        methods.each { |m| shackle_method(m, opts) }
      end

      def shackle_method(method, opts)
        @shackles_module ||= begin
          m = Module.new
          self.prepend m
          m
        end

        @shackles_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
         def #{method}(*args)
           Shackles.activate(#{opts[:environment].inspect}) { super }
         end
        RUBY
      end
    end
  end
end
