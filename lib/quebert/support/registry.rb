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
    
    # Stores classes at retreives a key for class and subclasses.
    # TODO 
    #   * make this thing match on most specific subclass
    class ClassRegistry < Registry
      # Returns a class from a given instance
      def[](key)
        case key
        when Class
          # Find the class key based on the class or subclass of the incoming key/klass
          if klass = keys.map{|klass| Support.constantize(klass) }.find{|k| k >= key}
            # If we find a matching class/subclass then pull this out
            super klass.name.to_sym
          end
        else
          super
        end
      end
    end
  end
end