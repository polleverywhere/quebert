module Quebert
  class Worker
    include Logging

    attr_accessor :exception_handler, :backend, :queues

    def initialize
      @queues = []
      yield self if block_given?
    end

    # Start the worker backend and intercept exceptions if a handler is provided
    def start
      Signal.trap('TERM') { safe_stop }
      Signal.trap('INT') { safe_stop }

      logger.info "Worker started with #{backend.class.name} backend\n"

      backend.queues = queues if backend.respond_to?(:queues=)

      while @controller = backend.reserve do
        begin
          @controller.perform
        rescue => error
          if exception_handler
            exception_handler.call(
              error,
              :controller => @controller,
              :pid => $$,
              :worker => self
            )
          else
            raise
          end
        end
        @controller = nil

        stop if @terminate_sent
      end
    end

    def safe_stop
      if @terminate_sent
        logger.info "Ok! I get the point. Shutting down immediately."
        stop
      else
        logger.info "Finishing current job then shutting down."
        @terminate_sent = true
        stop unless @controller
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
