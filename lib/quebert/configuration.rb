module Quebert
  class Configuration
    attr_accessor :backend
    
    def self.from_hash(hash)
      hash, config = Support.symbolize_keys(hash), new
      # Find out backend from the registry and configure
      if backend = Quebert.backends[hash.delete(:backend).to_sym]
        # If the backend supports configuration, do it!
        p backend
        config.backend = backend.respond_to?(:configure) ? backend.configure(Support.symbolize_keys(hash)) : backend.new
      end
      config
    end
  end
end