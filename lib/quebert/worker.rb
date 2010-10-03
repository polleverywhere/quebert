require 'logger'

module Quebert
  class Worker
    attr_accessor :exception_handler, :log_file, :backend
    
    include Quebert::Daemonizable
    
    def initialize
      yield self if block_given?
    end
    
    # Start the worker backend and intercept exceptions if a handler is provided
    def start
      while job = backend.reserve do
        begin
          job.perform
        rescue Exception => e
          exception_handler ? exception_handler.call(e) : raise(e)
        end
      end
    end
    
  protected
    def log(message)
      puts message
    end
  end
end