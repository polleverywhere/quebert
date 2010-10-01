module Quebert
  module AsyncSend
    
    class InstanceJob < Job
      def call(klass, initialize_args, meth, args)
        Support.constantize(klass).new(initialize_args).send(meth, *args)
      end
    end
    
    class ClassJob < Job
      def call(klass, meth, args)
        Support.constantize(klass).send(meth, *args)
      end
    end
    
    def self.included(base)
      base.send :extend,  ClassMethods
      base.send :include, InstanceMethods
    end
    
    Configuration = Struct.new(:producer)
    
    module ClassMethods
      def async_sender
        @async_sender ||= Configuration.new(Producer.new)
      end
      
      def async_send(meth, *args)
        async_sender.producer.put ClassJob.new(self, meth, *args)
      end
    end
    
    module InstanceMethods
      def async_send(meth, *args)
        self.class.async_sender.producer.put InstanceJob.new(self.class, id, meth, *args)
      end
    end
    
  end
end