require 'beaneater'

module Quebert
  module Backend
    
    # Manage jobs on a Beanstalk queue out of process
    class Beanstalk
      def initialize(host, tube_name)
        @host, @tube_name = host, tube_name
      end

      def put(job, *args)
        priority, delay, ttr = args
        opts = {}
        opts[:pri]   = priority unless priority.nil?
        opts[:delay] = delay    unless delay.nil?
        opts[:ttr]   = ttr      unless ttr.nil?
        tube.put job.to_json, opts
      end

      def reserve_without_controller(timeout=nil)
        tube.reserve timeout
      end

      def reserve(timeout=nil)
        Controller::Beanstalk.new reserve_without_controller(timeout), self
      end

      def peek(state)
        tube.peek state
      end

      # For testing purposes... I think there's a better way to do this though.
      def drain!
        while peek(:ready) do
          reserve_without_controller.delete
        end
        while peek(:delayed) do
          reserve_without_controller.delete
        end
        while peek(:buried) do
          tube.kick
          reserve_without_controller.delete
        end
      end
      
      def self.configure(opts={})
        opts[:host] ||= ['127.0.0.1:11300']
        new(opts[:host], opts[:tube])
      end

      private
      def pool
        @pool ||= Beaneater::Pool.new Array(@host)
      end

      def tube
        @tube ||= pool.tubes[@tube_name]
      end
    end
  end
end