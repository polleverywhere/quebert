module Quebert
  module AsyncSender
    # Perform jobs on Object methods (not instances)
    module Object
      class ObjectJob < Job
        def perform(const, meth, args)
          Support.constantize(const).send(meth, *args)
        end
      end
      
      def self.included(base)
        base.send(:extend, ClassMethods)
      end
      
      module ClassMethods
        def async_send(meth, *args)
          ObjectJob.new(self.name, meth, args).enqueue
        end
      end
    end
  end
end