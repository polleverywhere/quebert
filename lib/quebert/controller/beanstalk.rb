require 'benchmark'

module Quebert
  module Controller
    # Handle interactions between a job and a Beanstalk queue.
    class Beanstalk < Base
      include Logging

      attr_reader :beanstalk_job, :queue, :job

      MAX_TIMEOUT_RETRY_DELAY = 300
      TIMEOUT_RETRY_DELAY_SEED = 2
      TIMEOUT_RETRY_GROWTH_RATE = 3

      def initialize(beanstalk_job, queue)
        @beanstalk_job, @queue = beanstalk_job, queue
        @job = Job.from_json(beanstalk_job.body)
        @job.instance_variable_set('@controller', self)
      rescue Exception => e
        beanstalk_job.bury
        log "Exception caught on initialization. #{e.inspect}", :error
        raise
      end

      def delete
        beanstalk_job.delete
        log "Deleted on initialization", :error
      end

      def release
        beanstalk_job.release :pri => @job.priority, :delay => @job.delay
        log "Released on initialization with priority: #{@job.priority} and delay: #{@job.delay}", :error
      end

      def bury
        beanstalk_job.bury
        log "Buried on initialization", :error
      end



      def perform
        log "Performing with args #{job.args.inspect}"
        log "Beanstalk Job Stats: #{beanstalk_job.stats.inspect}"

        result = false
        time = Benchmark.realtime do
          result = job.perform!
          beanstalk_job.delete
        end

        log "Completed in #{(time*1000*1000).to_i/1000.to_f} ms\n"
        result
      rescue Timeout::Error => e
        log "Job timed out. Retrying with delay. #{e.inspect} #{e.backtrace.join("\n")}", :error
        retry_with_delay
        raise
      rescue Exception => e
        log "Exception caught on perform. Burying job. #{e.inspect} #{e.backtrace.join("\n")}", :error
        beanstalk_job.bury
        log "Job buried", :error
        raise
      end

    protected
      def retry_with_delay
        delay = TIMEOUT_RETRY_DELAY_SEED + TIMEOUT_RETRY_GROWTH_RATE**beanstalk_job.stats["releases"].to_i

        if delay > MAX_TIMEOUT_RETRY_DELAY
          log "Max retry delay exceeded. Burrying job"
          beanstalk_job.bury
          log "Job burried"
        else
          log "TTR exceeded. Releasing with priority: #{@job.priority} and delay: #{delay}"
          beanstalk_job.release :pri => @job.priority, :delay => delay
          log "Job released"
        end
      rescue ::Beaneater::NotFoundError
        log "Job ran longer than allowed. Beanstalk already deleted it!!!!", :error
        # Sometimes the timer doesn't behave correctly and this job actually runs longer than
        # allowed. At that point the beanstalk job no longer exists anymore. Lets let it go and don't blow up.
      end

      def log(message, level=:info)
        # Have the job write to the log file so that we catch the details of the job
        job.send(:log, message, level)
      end
    end
  end
end
