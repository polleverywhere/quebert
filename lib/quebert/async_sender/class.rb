module Quebert
  module AsyncSender
    # Extend a class with both the object and instance async_send
    module Class
      def self.included(base)
        base.send(:include, AsyncSender::Object)
        base.send(:include, AsyncSender::Instance)
      end
    end
  end
end