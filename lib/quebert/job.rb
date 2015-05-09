require 'json'
require 'timeout'

module Quebert
  class Job
    include Logging

    attr_reader :args
    attr_accessor :priority, :delay, :ttr

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

    # A buffer time in seconds added to the Beanstalk TTR for Quebert to do its own job cleanup
    # The job will perform based on the Beanstalk TTR, but Beanstalk hangs on to the job just a
    # little longer so that Quebert can bury the job or schedule a retry with the appropriate delay
    QUEBERT_TTR_BUFFER = 5

    # Exceptions are used for signaling job status... ewww. Yank this out and
    # replace with a more well thought out controller.
    NotImplemented = Class.new(StandardError)
    Action  = Class.new(Exception)
    Bury    = Class.new(Action)
    Delete  = Class.new(Action)
    Release = Class.new(Action)
    Timeout = Class.new(Action)
    Retry   = Class.new(Action)

    def initialize(*args)
      @priority = Job::Priority::MEDIUM
      @delay    = DEFAULT_JOB_DELAY
      @ttr      = DEFAULT_JOB_TTR
      @args     = args.dup.freeze
      yield self if block_given?
      self
    end

    def perform(*args)
      raise NotImplemented
    end

    # Runs the perform method that somebody else should be implementing
    def perform!
      Quebert.config.before_job(self)
      Quebert.config.around_job(self)

      # Honor the timeout and kill the job in ruby-space. Beanstalk
      # should be cleaning up this job and returning it to the queue
      # as well.
      val = ::Timeout.timeout(ttr, Job::Timeout){ perform(*args) }

      Quebert.config.around_job(self)
      Quebert.config.after_job(self)

      val
    end

    # Accepts arguments that override the job options and enqueu this stuff.
    def enqueue(opts={})
      opts.each { |opt, val| self.send("#{opt}=", val) }
      backend.put(self, priority, delay, ttr + QUEBERT_TTR_BUFFER)
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
    def delete!
      raise Delete
    end

    def release!
      raise Release
    end

    def bury!
      raise Bury
    end
  end
end
