require 'logger'

module Quebert
  module Logging
    protected
    def logger
      @logger ||= Quebert.logger
    end
    
     # Making logging jobs a tiny bit easier..
    def log(message, level=:info)
      logger.send(level, "[##{self.object_id} #{self.class.name}] : #{message}")
    end
  end
end