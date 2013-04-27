module Quebert
  module AsyncSender
    # Perform jobs on Object methods (not instances)
    module Object
      class ObjectJob < Job
        def perform(const, meth, *args)
          Support.constantize(const).send(meth, *args)
        end
      end
      
      def self.included(base)
        base.send(:extend, ClassMethods)
        base.send(:extend, AsyncSender::Promise::DSL)
      end
      
      module ClassMethods
        def build_job(meth, *args)
          ObjectJob.new(self.name, meth, *args)
        end
      end
    end
  end
end