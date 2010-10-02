module Quebert
  module AsyncSender
    
    module ActiveRecord
      class RecordJob < Job
        def perform(klass, id, meth, args)
          Support.constantize(klass).find(id).send(meth, *args)
        end
      end
      
      def self.included(base)
        base.send :extend,  ClassMethods
        base.send :include, InstanceMethods
      end
      
      module InstanceMethods
        def async_send(meth, *args)
          RecordJob.enqueue(self.class.name, id, meth, args)
        end
      end
      
      module ClassMethods
      end
    end
    
    # Augment a class to asycnronously send messages for both instances
    # and classes.
    module Klass
      class KlassJob < Job
        def perform(klass, meth, args)
          Support.constantize(klass).send(meth, args)
        end
      end
      
      class InstanceJob < Job
        def perform(klass, init_args, meth, args)
          Support.constantize(klass).new(init_args).send(meth, args)
        end
      end
      
      def self.included(base)
        base.send :extend,  ClassMethods
        base.send :include, InstanceMethods
        
        # Intercept the arguments that we initialize the class with
        base.class_eval do
          alias :initialize_without_async_send :initialize
          alias :initialize :initialize_with_async_send
        end
      end
      
      module ClassMethods
        def async_send(meth, *args)
          KlassJob.enqueue(self.name, meth, args)
        end
      end
      
      module InstanceMethods
        def async_send(meth, *args)
          InstanceJob.enqueue(self.class.name, @_init_args, meth, args)
        end
        
        def initialize_with_async_send(*args)
          @_init_args = args
          initialize_without_async_send(*args)
        end
      end
    end
    
  end  
end