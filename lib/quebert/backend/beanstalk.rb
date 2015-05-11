require "beaneater"
require "forwardable"

module Quebert
  module Backend
    # Manage jobs on a Beanstalk queue out of process
    class Beanstalk
      extend Forwardable
      include Logging

      attr_reader :host, :default_queue_name
      attr_writer :queue_names

      def initialize(host, default_queue_name)
        @host = host
        @default_queue_name = default_queue_name
        @queue_names = []
      end

      def self.configure(opts = {})
        new(opts.fetch(:host, "127.0.0.1:11300"), opts.fetch(:default_queue))
      end

      def queue(queue_name)
        Queue.new(beanstalkd_tubes[queue_name])
      end

      def reserve_without_controller(timeout=nil)
        watch_queues
        beanstalkd_tubes.reserve(timeout)
      end

      def reserve(timeout=nil)
        Controller::Beanstalk.new(reserve_without_controller(timeout))
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
          default_queue.kick
          reserve_without_controller.delete
        end
      end

      def_delegators :default_queue, :put, :peek

      private

      def default_queue
        @default_queue ||= queue(default_queue_name)
      end

      def beanstalkd_connection
        @beanstalkd_connection ||= Beaneater.new(host)
      end

      def beanstalkd_tubes
        beanstalkd_connection.tubes
      end

      def watch_queues
        if queue_names != @watched_queue_names
          @watched_queue_names = queue_names
          logger.info "Watching beanstalkd queues #{@watched_queue_names.inspect}"
          beanstalkd_tubes.watch!(*@watched_queue_names)
        end
      end

      def queue_names
        @queue_names.empty? ? [default_queue_name] : @queue_names
      end
    end

    class Beanstalk::Queue
      extend Forwardable
      attr_reader :beanstalkd_tube
      def initialize(beanstalkd_tube)
        @beanstalkd_tube = beanstalkd_tube
      end

      def put(job, *args)
        priority, delay, ttr = args
        opts = {}
        opts[:pri]   = priority if priority
        opts[:delay] = delay    if delay
        opts[:ttr]   = ttr      if ttr
        beanstalkd_tube.put(job.to_json, opts)
      end

      def_delegators :beanstalkd_tube, :peek, :kick
    end
  end
end
