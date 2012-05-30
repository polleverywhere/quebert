require 'json'

module Quebert
  class Job
    include Logging

    attr_reader :args
    attr_accessor :priority, :delay, :ttr
    
    DEFAULT_JOB_PRIORITY = 65536
    DEFAULT_JOB_DELAY = 0
    DEFAULT_JOB_TTR = 10

    # A buffer time in seconds added to the Beanstalk TTR for Quebert to do its own job cleanup 
    # The job will perform based on the Beanstalk TTR, but Beanstalk hangs on to the job just a
    # little longer so that Quebert can bury the job or schedule a retry with the appropriate delay
    QUEBERT_TTR_BUFFER = 5

    NotImplemented = Class.new(StandardError)
    
    Action  = Class.new(Exception)
    
    Bury    = Class.new(Action)
    Delete  = Class.new(Action)
    Release = Class.new(Action)
    Timeout = Class.new(Action)
    Retry   = Class.new(Action)

    def initialize(*args)
      opts = args.last.is_a?(::Hash) ? args.pop : nil
      
      @priority = DEFAULT_JOB_PRIORITY
      @delay = DEFAULT_JOB_DELAY
      @ttr = DEFAULT_JOB_TTR

      if opts
        beanstalk_opts = opts.delete(:beanstalk)
        args << opts unless opts.empty?
        
        if beanstalk_opts
          @priority = beanstalk_opts[:priority] if beanstalk_opts[:priority]
          @delay = beanstalk_opts[:delay] if beanstalk_opts[:delay]
          @ttr = beanstalk_opts[:ttr] if beanstalk_opts[:ttr]
        end
      end

      @args = args.dup.freeze
    end
    
    def perform(*args)
      raise NotImplemented
    end
    
    # Runs the perform method that somebody else should be implementing
    def perform!
      # Honor the timeout and kill the job in ruby-space. Beanstalk
      # should be cleaning up this job and returning it to the queue
      # as well.
      begin
        Quebert::Timeout.timeout(@ttr){ perform(*args) }
      rescue ::Timeout::Error => e
        log e.backtrace.join('\n'), :error
        raise Job::Timeout, e.message, caller
      end
    end
    
    def enqueue
      self.class.backend.put self, @priority, @delay, @ttr + QUEBERT_TTR_BUFFER
    end
    
    def to_json
      JSON.generate(Serializer::Job.serialize(self))
    end
    
    def self.from_json(json)
      if hash = JSON.parse(json) and not hash.empty?
        Serializer::Job.deserialize(hash)
      end
    end
    
    def self.backend=(backend)
      @backend = backend
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