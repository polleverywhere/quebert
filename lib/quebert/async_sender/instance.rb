module Quebert
  module AsyncSender
    # Perform jobs on instances of classes
    module Instance
      class InstanceJob < Job
        def perform(klass, init_args, meth, *args)
          Support.constantize(klass).new(*init_args).send(meth, *args)
        end
      end
      
      def self.included(base)
        # Its not as simple as including initialize in a class, we
        # have to do some tricks to make it work so we can put the include
        # before the initialize method as opposed to after. Ah, and thanks PivotalLabs for this.
        base.extend ClassMethods
        base.overwrite_initialize
        base.instance_eval do
          def method_added(name)
            return if name != :initialize
            overwrite_initialize
          end
        end
      end
      
      def initialize_with_async_sender(*args,&block)
        initialize_without_async_sender(*(@_init_args = args),&block)
      end
      
      module ClassMethods
        def overwrite_initialize
          class_eval do
            unless method_defined?(:initialize_with_async_sender)
              define_method(:initialize_with_async_sender) do
                initialize_without_async_sender
              end
            end
            
            if instance_method(:initialize) != instance_method(:initialize_with_async_sender)
              alias_method :initialize_without_async_sender, :initialize
              alias_method :initialize, :initialize_with_async_sender
            end
          end
        end
      end
      
      def async_send(meth, *args)
        InstanceJob.new(self.class.name, @_init_args, meth, *args).enqueue
      end
    end
  end
end