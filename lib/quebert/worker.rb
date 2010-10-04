require 'logger'

module Quebert
  class Worker
    attr_accessor :exception_handler, :logger, :backend
    
    def initialize
      yield self if block_given?
    end
    
    # Start the worker backend and intercept exceptions if a handler is provided
    def start
      logger.info "Worker pid##{Process.pid} started with #{backend.class.name} backend"
      while consumer = backend.reserve do
        begin
          log consumer.job, "performing with args #{consumer.job.args.inspect}"
          consumer.perform
          log consumer.job, "complete"
        rescue Exception => e
          log consumer.job, "fault #{e}", :error
          exception_handler ? exception_handler.call(e) : raise(e)
        end
      end
    end
    
  protected
    def log(job, message, level=:info)
      logger.send(level, "#{job.class.name}##{job.object_id}: #{message}")
    end
    
    def logger
      @logger ||= Quebert.logger
    end
    
    def backend
      @backend ||= Quebert.config.backend
    end
  end
end