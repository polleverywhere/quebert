require 'system_timer'

module Quebert
  class Worker
    include Logging

    attr_accessor :exception_handler, :backend

    def initialize
      yield self if block_given?
    end

    # Start the worker backend and intercept exceptions if a handler is provided
    def start
      Signal.trap('TERM') { safe_stop }
      Signal.trap('INT') { safe_stop }

      logger.info "Worker started with #{backend.class.name} backend\n  => #{self.inspect}\n"
      while @controller = reserve_with_timeout do
        logger.error "Reserved job => #{@controller.inspect}"
        begin
          @controller.perform
        rescue Exception => error
          if exception_handler
            exception_handler.call(
              error,
              :controller => @controller,
              :pid => $$,
              :worker => self
            )
          else
            raise error
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

    RESERVE_TIMEOUT = 15

    def reserve_with_timeout
      # We'll time out the connection our selves, if the server don't do it!
      ::SystemTimer.timeout_after(RESERVE_TIMEOUT + 2) do
        return backend.reserve RESERVE_TIMEOUT
      end
    rescue ::Timeout::Error
      logger.error "Client reserve timeout. Let's close the connection..."
      backend.close
      retry
    rescue ::Beanstalk::DeadlineSoonError, Exception
      logger.error "Reserve timed out! Retrying..."
      retry
    end
  end
end
