module Quebert
  module AsyncSender
    # I'm not sure if I want to do this or build serializers per type of object...
    module ActiveRecord
      class RecordJob < Job
        def perform(record, meth, *args)
          record.send(meth, *args)
        end
      end
      
      def self.included(base)
        base.send(:include, AsyncSender::Promise::DSL)
        base.send(:include, AsyncSender::Object)
        base.send(:include, InstanceMethods)
      end

      module InstanceMethods
        def build_job(meth, *args)
          RecordJob.new(self, meth, *args)
        end
      end
    end
  end
end