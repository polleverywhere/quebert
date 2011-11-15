require 'logger'

module Quebert
  class Configuration
    attr_accessor :backend, :logger, :worker
    
    def logger
      @logger ||= begin
        l = Logger.new($stdout)
        l.formatter = Logger::Formatter.new
        l
      end
    end
    
    def log_file_path=(path)
      self.logger = begin
        l = Logger.new(path)
        l.formatter = Logger::Formatter.new
        l
      end
    end
    
    def from_hash(hash)
      hash = Support.symbolize_keys(hash)
      # Find out backend from the registry and configure
      if backend = Quebert.backends[hash.delete(:backend).to_sym]
        # If the backend supports configuration, do it!
        self.backend = backend.respond_to?(:configure) ? backend.configure(Support.symbolize_keys(hash)) : backend.new
      end
      self
    end
    
    def worker
      @worker ||= Struct.new(:exception_handler).new
    end
    
    def self.from_hash(hash)
      new.from_hash(hash) # Config this puppy up from a config hash
    end
  end
end