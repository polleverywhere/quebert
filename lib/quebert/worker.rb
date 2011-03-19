require 'logger'

module Quebert
  class Worker
    attr_accessor :exception_handler, :logger, :backend
    
    def initialize
      yield self if block_given?
    end
    
    # Start the worker backend and intercept exceptions if a handler is provided
    def start
      Signal.trap('TERM'){ stop }
      
      logger.info "Worker pid##{Process.pid} started with #{backend.class.name} backend"
      while controller = backend.reserve do
        begin
          log controller.job, "performing with args #{controller.job.args.inspect}."
          log controller.job, "Priority: #{controller.beanstalk_job.pri}, Delay: #{controller.beanstalk_job.delay}, TTR: #{controller.beanstalk_job.ttr}" if controller.respond_to?(:beanstalk_job)
          controller.perform
          log controller.job, "complete"
        rescue Exception => e
          log controller.job, "fault #{e}", :error
          exception_handler ? exception_handler.call(e) : raise(e)
        end
      end
    end
    
    def stop
      logger.info "Worker pid##{Process.pid} stopping"
      exit 0
    end
    
  protected
    # Setup a bunch of stuff with Quebert config defaults the we can override later.
    def logger
      @logger ||= Quebert.logger
    end
    
    def backend
      @backend ||= Quebert.config.backend
    end
    
    def exception_handler
      @exception_handler ||= Quebert.config.worker.exception_handler
    end
    
    # Making logging jobs a tiny bit easier..
    def log(job, message, level=:info)
      logger.send(level, "#{job.class.name}##{job.object_id}: #{message}")
    end
  end
end