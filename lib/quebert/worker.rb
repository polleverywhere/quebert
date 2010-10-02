require 'logger'

module Quebert
  class Worker
    attr_reader :queue
    attr_accessor :exception_handler, :logger
    
    include Daemonizable
    
    def initialize(queue)
      @queue = queue
      @logger = Logger.new($stdout)
      yield self if block_given?
    end
    
    # Start the worker queue and intercept exceptions if a handler is provided
    def start
      while job = queue.reserve do
        begin
          job.perform
        rescue Exception => e
          exception_handler ? exception_handler.call(e) : raise(e)
        end
      end
    end
    
  protected
    def log(message)
      logger.info(message)
    end
  end
end