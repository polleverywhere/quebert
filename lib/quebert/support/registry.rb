module Quebert
  module Support
    class Registry < Hash
      def register(key, val)
        self[key.to_sym] = val
      end
    
      def unregister(key)
        self.delete(key.to_sym)
      end
    end
  end
end