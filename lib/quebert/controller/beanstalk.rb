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

        begin
          @job = Job.from_json(beanstalk_job.body)
        rescue Job::Delete
          beanstalk_job.delete
          log "Deleted on initialization", :error
        rescue Job::Release
          beanstalk_job.release @job.priority, @job.delay
          log "Released on initialization with priority: #{@job.priority} and delay: #{@job.delay}", :error
        rescue Job::Bury
          beanstalk_job.bury
          log "Buried on initialization", :error
        rescue Exception => e
          beanstalk_job.bury
          log "Exception caught on initialization. #{e.inspect}", :error
          raise e  
        end
      end
      
      def perform
        begin
          log "Performing with args #{job.args.inspect}"
          log "Beanstalk Job Stats: #{beanstalk_job.stats.inspect}"

          result = false
          time = Benchmark.realtime do
            result = job.perform!
            beanstalk_job.delete
          end

          log "Completed in #{(time*1000*1000).to_i/1000.to_f} ms\n"
          result
        rescue Job::Delete
          beanstalk_job.delete
          log "Deleted", :error
        rescue Job::Release
          beanstalk_job.release @job.priority, @job.delay
          log "Released with priority: #{@job.priority} and delay: #{@job.delay}", :error 
        rescue Job::Bury
          beanstalk_job.bury
          log "Burried", :error
        rescue Job::Timeout => e
          retry_with_delay
          raise e
        rescue Job::Retry => e
          # The difference between the Retry and Timeout class is that
          # Retry does not log an exception where as Timeout does
          log "Manually retrying with delay"
          retry_with_delay
        rescue Exception => e
          beanstalk_job.bury
          log "Exception caught on perform. Job buried. #{e.inspect}", :error
          raise e
        end
      end

    protected
      def retry_with_delay
        delay = TIMEOUT_RETRY_DELAY_SEED + TIMEOUT_RETRY_GROWTH_RATE**beanstalk_job.stats["releases"].to_i

        if delay > MAX_TIMEOUT_RETRY_DELAY
          beanstalk_job.bury
          log "Max retry delay exceeded. Burrying job."
        else
          beanstalk_job.release @job.priority, delay
          log "TTR exceeded. Releasing with priority: #{@job.priority} and delay: #{delay}"
        end
      end

      def log(message, level=:info)
        # Have the job write to the log file so that we catch the details of the job
        job.send(:log, message, level)
      end
    end
  end
end