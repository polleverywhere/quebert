module Quebert
  module Support
    # Borrowed from Rails ActiveSupport
    def self.constantize(camel_cased_word) #:nodoc:
      names = camel_cased_word.split('::')
      names.shift if names.empty? || names.first.empty?

      constant = Object
      names.each do |name|
        constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
      end
      constant
    end
    
    def self.symbolize_keys(hash)
      hash.inject({}){|h, (k,v)| h[k.to_sym] = v; h; }
    end
  end
end