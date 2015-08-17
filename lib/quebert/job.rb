require 'json'
require 'timeout'

module Quebert
  class Job
    include Logging
    extend Forwardable

    attr_reader :args
    attr_accessor :priority, :delay, :ttr, :queue, :controller

    # Prioritize Quebert jobs as specified in https://github.com/kr/beanstalkd/blob/master/doc/protocol.txt.
    class Priority
      LOW     = 2**32
      MEDIUM  = LOW / 2
      HIGH    = 0
    end

    # Delay a job for 0 seconds on the jobqueue
    DEFAULT_JOB_DELAY = 0

    # By default, the job should live for 10 seconds tops.
    DEFAULT_JOB_TTR = 10

    # Catch timeouts thrown by Quebert jobs.
    Timeout = Class.new(::Timeout::Error)

    def initialize(*args)
      @priority = Job::Priority::MEDIUM
      @delay    = DEFAULT_JOB_DELAY
      @ttr      = DEFAULT_JOB_TTR
      @args     = args.dup.freeze
      yield self if block_given?
      self
    end

    def perform(*args)
      raise NotImplementedError
    end

    # Runs the perform method that somebody else should be implementing
    def perform!(controller = default_controller)
      @controller = controller
      before_perform
      # Honor the timeout and kill the job in ruby-space. Beanstalk
      # should be cleaning up this job and returning it to the queue
      # as well.
      val = ::Timeout.timeout(ttr, Job::Timeout){ perform(*args) }
      after_perform
      val
    rescue Job::Timeout => e
      timeout! e
    end

    def default_controller
      Quebert::Controller::Base.new(self)
    end

    def before_perform
      Quebert.config.before_job(self)
      Quebert.config.around_job(self)
    end

    def after_perform
      Quebert.config.around_job(self)
      Quebert.config.after_job(self)
    end

    # Can be overridden by the job implementation for
    # custom exception handling hooks.
    def handle_error(error, worker)
      # TODO - Change the behavior of this method to
      # log the error and bury the job. Get rid of everything
      # else.
      logger.error [error.inspect, worker.inspect].join

      # TODO - Kill this stupid hook
      if handler = worker.exception_handler
        handler.call(
          error,
          :controller => controller,
          :pid => $$,
          :worker => worker
        )
      else
        raise
      end

    end

    # Accepts arguments that override the job options and enqueu this stuff.
    def enqueue(override_opts={})
      override_opts.each { |opt, val| self.send("#{opt}=", val) }
      backend.put(self)
    end

    # Serialize the job into a JSON string that we can put on the beandstalkd queue.
    def to_json
      JSON.generate(Serializer::Job.serialize(self))
    end

    # Read a JSON string and convert into a hash that Ruby can deal with.
    def self.from_json(json)
      if hash = JSON.parse(json) and not hash.empty?
        Serializer::Job.deserialize(hash)
      end
    end

    def self.backend=(backend)
      @backend = backend
    end

    def backend
      self.class.backend
    end

    def self.backend
      @backend || Quebert.configuration.backend
    end

  protected
    def_delegators :@controller, :delete!, :release!, :bury!, :timeout!
  end
end
