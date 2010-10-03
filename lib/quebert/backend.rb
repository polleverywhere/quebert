module Quebert
  module Backend
    autoload :InProcess,  'quebert/backend/in_process.rb'
    autoload :Beanstalk,  'quebert/backend/beanstalk.rb'
    autoload :Sync,       'quebert/backend/sync.rb'
    
    def self.register(name, backend)
      Quebert.backends[name.to_sym] = backend
    end
  end
end