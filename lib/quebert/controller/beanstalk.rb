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
      rescue => e
        beanstalk_job.bury
        logger.error "Error caught on initialization. #{e.inspect}"
        raise
      end

      def perform
        logger.error(job) { "Performing with args #{job.args.inspect}" }
        logger.error(job) { "Beanstalk Job Stats: #{beanstalk_job.stats.inspect}" }

        result = false
        time = Benchmark.realtime do
          result = job.perform!
          beanstalk_job.delete
        end

        logger.error(job) { "Completed in #{(time*1000*1000).to_i/1000.to_f} ms\n" }
        result
      rescue Job::Delete
        logger.info(job) { "Deleting job" }
        beanstalk_job.delete
        logger.info(job) { "Job deleted" }
      rescue Job::Release
        logger.info(job) { "Releasing with priority: #{job.priority} and delay: #{job.delay}" }
        beanstalk_job.release :pri => job.priority, :delay => job.delay
        logger.info(job) { "Job released" }
      rescue Job::Bury
        logger.info(job) { "Burrying job" }
        beanstalk_job.bury
        logger.info(job) { "Job burried" }
      rescue Job::Timeout => e
        logger.info(job) { "Job timed out. Retrying with delay. #{e.inspect} #{e.backtrace.join("\n")}" }
        retry_with_delay
        raise
      rescue Job::Retry
        # The difference between the Retry and Timeout class is that
        # Retry does not logger.error(job) { an exception where as Timeout does }
        logger.info(job) { "Manually retrying with delay" }
        retry_with_delay
      rescue => e
        logger.error(job) { "Error caught on perform. Burying job. #{e.inspect} #{e.backtrace.join("\n")}" }
        beanstalk_job.bury
        logger.error(job) { "Job buried" }
        raise
      end

    protected
      def retry_with_delay
        delay = TIMEOUT_RETRY_DELAY_SEED + TIMEOUT_RETRY_GROWTH_RATE**beanstalk_job.stats["releases"].to_i

        if delay > MAX_TIMEOUT_RETRY_DELAY
          logger.error(job) { "Max retry delay exceeded. Burrying job" }
          beanstalk_job.bury
          logger.error(job) { "Job burried" }
        else
          logger.error(job) { "TTR exceeded. Releasing with priority: #{job.priority} and delay: #{delay}" }
          beanstalk_job.release :pri => job.priority, :delay => delay
          logger.error(job) { "Job released" }
        end
      rescue ::Beaneater::NotFoundError
        logger.error(job) { "Job ran longer than allowed. Beanstalk already deleted it!!!!" }
        # Sometimes the timer doesn't behave correctly and this job actually runs longer than
        # allowed. At that point the beanstalk job no longer exists anymore. Lets let it go and don't blow up.
      end
    end
  end
end
