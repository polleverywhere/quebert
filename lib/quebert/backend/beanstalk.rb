require "beaneater"
require "forwardable"

module Quebert
  module Backend
    # Manage jobs on a Beanstalk queue out of process
    class Beanstalk
      extend Forwardable

      attr_reader :host, :default_tube_name
      attr_accessor :queues

      def initialize(host, default_tube_name)
        @host, @default_tube_name = host, default_tube_name
        @queues = []
      end

      def self.configure(opts = {})
        opts[:host] ||= ['127.0.0.1:11300']
        new(opts[:host], opts[:tube])
      end

      def tube(tube_name)
        Tube.new(connection.tubes[tube_name])
      end

      def reserve_without_controller(timeout=nil)
        watch_tubes
        connection.tubes.reserve(timeout)
      end

      def reserve(timeout=nil)
        Controller::Beanstalk.new(reserve_without_controller(timeout), self)
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
          default_tube.kick
          reserve_without_controller.delete
        end
      end

      def_delegators :default_tube, :put, :peek

      private

      def default_tube
        @default_tube ||= tube(default_tube_name)
      end

      def connection
        @connection ||= Beaneater.new(host)
      end

      def watch_tubes
        connection.tubes.watch!(*watched_tube_names)
      end

      def watched_tube_names
        queues.empty? ? [default_tube_name] : queues
      end
    end

    class Beanstalk::Tube
      extend Forwardable
      attr_reader :tube
      def initialize(tube)
        @tube = tube
      end

      def put(job, *args)
        priority, delay, ttr = args
        opts = {}
        opts[:pri]   = priority unless priority.nil?
        opts[:delay] = delay    unless delay.nil?
        opts[:ttr]   = ttr      unless ttr.nil?
        tube.put job.to_json, opts
      end

      def_delegators :tube, :peek, :kick
    end
  end
end
