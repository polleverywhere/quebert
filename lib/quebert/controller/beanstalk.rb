require 'benchmark'

module Quebert
  module Controller
    # Handle interactions between a job and a Beanstalk queue.
    class Beanstalk < Base
      include Logging

      attr_reader :beanstalk_job, :job

      MAX_TIMEOUT_RETRY_DELAY = 300
      TIMEOUT_RETRY_DELAY_SEED = 2
      TIMEOUT_RETRY_GROWTH_RATE = 3

      def initialize(beanstalk_job)
        @beanstalk_job = beanstalk_job
        @job = Job.from_json(beanstalk_job.body)
      rescue Job::Delete
        beanstalk_job.delete
        job_log "Deleted on initialization", :error
      rescue Job::Release
        beanstalk_job.release job.priority, job.delay
        job_log "Released on initialization with priority: #{job.priority} and delay: #{job.delay}", :error
      rescue Job::Bury
        beanstalk_job.bury
        job_log "Buried on initialization", :error
      rescue => e
        beanstalk_job.bury
        job_log "Error caught on initialization. #{e.inspect}", :error
        raise
      end

      def perform
        job_log "Performing with args #{job.args.inspect}"
        job_log "Beanstalk Job Stats: #{beanstalk_job.stats.inspect}"

        result = false
        time = Benchmark.realtime do
          result = job.perform!
          beanstalk_job.delete
        end

        job_log "Completed in #{(time*1000*1000).to_i/1000.to_f} ms\n"
        result
      rescue Job::Delete
        job_log "Deleting job", :error
        beanstalk_job.delete
        job_log "Job deleted", :error
      rescue Job::Release
        job_log "Releasing with priority: #{job.priority} and delay: #{job.delay}", :error
        beanstalk_job.release :pri => job.priority, :delay => job.delay
        job_log "Job released", :error
      rescue Job::Bury
        job_log "Burrying job", :error
        beanstalk_job.bury
        job_log "Job burried", :error
      rescue Job::Timeout => e
        job_log "Job timed out. Retrying with delay. #{e.inspect} #{e.backtrace.join("\n")}", :error
        retry_with_delay
        raise
      rescue Job::Retry
        # The difference between the Retry and Timeout class is that
        # Retry does not job_log an exception where as Timeout does
        job_log "Manually retrying with delay"
        retry_with_delay
      rescue => e
        job_log "Error caught on perform. Burying job. #{e.inspect} #{e.backtrace.join("\n")}", :error
        beanstalk_job.bury
        job_log "Job buried", :error
        raise
      end

    protected
      def retry_with_delay
        delay = TIMEOUT_RETRY_DELAY_SEED + TIMEOUT_RETRY_GROWTH_RATE**beanstalk_job.stats["releases"].to_i

        if delay > MAX_TIMEOUT_RETRY_DELAY
          job_log "Max retry delay exceeded. Burrying job"
          beanstalk_job.bury
          job_log "Job burried"
        else
          job_log "TTR exceeded. Releasing with priority: #{job.priority} and delay: #{delay}"
          beanstalk_job.release :pri => job.priority, :delay => delay
          job_log "Job released"
        end
      rescue ::Beaneater::NotFoundError
        job_log "Job ran longer than allowed. Beanstalk already deleted it!!!!", :error
        # Sometimes the timer doesn't behave correctly and this job actually runs longer than
        # allowed. At that point the beanstalk job no longer exists anymore. Lets let it go and don't blow up.
      end

      def job_log(message, level=:info)
        # Have the job write to the log file so that we catch the details of the job
        if job
          job.send(:log, message, level)
        else
          Quebert.logger.send(level, message)
        end
      end
    end
  end
end
