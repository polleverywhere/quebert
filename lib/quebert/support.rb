module Quebert
  module Support
    
    autoload :PidFile,  'quebert/support/pid_file'
    autoload :Registry, 'quebert/support/registry'
    
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
      map_keys(hash, :to_sym)
    end
    
    def self.stringify_keys(hash)
      map_keys(hash, :to_s)
    end
    
  private
    def self.map_keys(hash, meth)
      hash.inject({}){|h, (k,v)| h[k.send(meth)] = v; h; }
    end
  end
end