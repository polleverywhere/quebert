require "beaneater"
require "forwardable"

module Quebert
  module Backend
    # Manage jobs on a Beanstalk queue out of process
    class Beanstalk
      extend Forwardable
      include Logging

      # A buffer time in seconds added to the Beanstalk TTR for Quebert to do
      # its own job cleanup The job will perform based on the Beanstalk TTR,
      # but Beanstalk hangs on to the job just a little longer so that Quebert
      # can bury the job or schedule a retry with the appropriate delay
      TTR_BUFFER = 5

      attr_reader :host, :queue
      attr_writer :queues

      def initialize(host, queue)
        @host = host
        @queue = queue
        @queues = []
      end

      def self.configure(opts = {})
        new(opts.fetch(:host, "127.0.0.1:11300"), opts.fetch(:queue))
      end

      def reserve_without_controller(timeout=nil)
        watch_tubes
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
          kick
          reserve_without_controller.delete
        end
      end

      # TODO add a queue param?
      def_delegators :default_tube, :peek, :kick

      def put(job)
        tube = beanstalkd_tubes[job.queue || queue]
        tube.put(job.to_json,
          :pri => job.priority,
          :delay => job.delay,
          :ttr => job.ttr + TTR_BUFFER)
      end

      private

      def default_tube
        @default_tube ||= beanstalkd_tubes[queue]
      end

      def beanstalkd_connection
        @beanstalkd_connection ||= Beaneater.new(host)
      end

      def beanstalkd_tubes
        beanstalkd_connection.tubes
      end

      def watch_tubes
        if queues != @watched_tube_names
          @watched_tube_names = queues
          logger.info "Watching beanstalkd queues #{@watched_tube_names.inspect}"
          beanstalkd_tubes.watch!(*@watched_tube_names)
        end
      end

      def queues
        @queues.empty? ? [queue] : @queues
      end
    end
  end
end
