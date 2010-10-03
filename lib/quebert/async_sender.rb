module Quebert
  module AsyncSender
    
    module ActiveRecord
      class RecordJob < Job
        def perform(klass, id, meth, args)
          Support.constantize(klass).find(id).send(meth, *args)
        end
      end
      
      def self.included(base)
        base.send :include, InstanceMethods
      end
      
      module InstanceMethods
        def async_send(meth, *args)
          RecordJob.enqueue(self.class.name, id, meth, args)
        end
      end
    end
    
    # Perform jobs on Object methods (not instances)
    module Object
      class ObjectJob < Job
        def perform(const, meth, args)
          Support.constantize(const).send(meth, args)
        end
      end
      
      def self.included(base)
        base.send(:extend, ClassMethods)
      end
      
      module ClassMethods
        def async_send(meth, *args)
          ObjectJob.enqueue(self.name, meth, args)
        end
      end
    end
    
    # Perform jobs on instances of classes
    module Instance
      class InstanceJob < Job
        def perform(klass, init_args, meth, args)
          Support.constantize(klass).new(init_args).send(meth, args)
        end
      end
      
      def self.included(base)
        # Its not as simple as including initialize in a class, we
        # have to do some tricks to make it work so we can put the include
        # before the initialize method as opposed to after
        base.extend ClassMethods
        base.overwrite_initialize
        base.instance_eval do
          def method_added(name)
            return if name != :initialize
            overwrite_initialize
          end
        end
      end
      
      def initialize_with_async_sender(*args)
        initialize_without_async_sender(*(@_init_args = args))
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
        InstanceJob.enqueue(self.class.name, @_init_args, meth, args)
      end
    end
    
    # Extend a class with both the object and instance async_send
    module Class
      def self.included(base)
        base.send(:include, AsyncSender::Object)
        base.send(:include, AsyncSender::Instance)
      end
    end
    
  end  
end