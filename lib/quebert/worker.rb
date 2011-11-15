module Quebert
  class Worker
    include Logging

    attr_accessor :exception_handler, :backend
    
    def initialize
      yield self if block_given?
    end
    
    # Start the worker backend and intercept exceptions if a handler is provided
    def start
      Signal.trap('TERM'){ stop }
      
      logger.info "Worker started with #{backend.class.name} backend\n"
      while controller = backend.reserve do
        begin
          controller.perform
        rescue Exception => e
          exception_handler ? exception_handler.call(e) : raise(e)
        end
      end
    end
    
    def stop
      logger.info "Worker stopping\n"
      exit 0
    end
    
  protected
    def backend
      @backend ||= Quebert.config.backend
    end
    
    def exception_handler
      @exception_handler ||= Quebert.config.worker.exception_handler
    end
  end
end