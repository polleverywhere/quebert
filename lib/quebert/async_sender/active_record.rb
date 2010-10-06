module Quebert
  module AsyncSender
    
    # I'm not sure if I want to do this or build serializers per type of object...
    module ActiveRecord
      class RecordJob < Job
        def perform(record, meth, args)
          record.send(meth, *args)
        end
      end
      
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.send(:include, AsyncSender::Object)
      end
      
      module InstanceMethods
        # The meat of dealing with ActiveRecord instances.
        def async_send(meth, *args)
          RecordJob.new(self, meth, args).enqueue
        end
      end
    end
    
  end
end