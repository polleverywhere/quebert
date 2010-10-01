module Quebert

  # The basic glue between a job and the specific queue implementation. This
  # handles exceptions that may be thrown by the Job and how the Job should
  # be put back on the queue, if at all.
  module Consumer
    
    # The most Consumer. Doesn't even accept the queue as an argument because there's nothing
    # a job can do to be rescheduled, etc.
    class Base
      attr_reader :job
      
      def initialize(job)
        @job = job
      end
      
      def perform
        begin
          job.perform(*job.args)
        rescue Job::Action
          # Nothing to do chief!
        end
      end
    end
    
    # Handle interactions between a job and a Beanstalk queue.
    class Beanstalk < Base
      attr_reader :beanstalk_job, :queue, :job
      
      def initialize(beanstalk_job, queue)
        @beanstalk_job, @queue = beanstalk_job, queue
        @job = Job.from_json(beanstalk_job.body)
      end
      
      def perform
        begin
          result = job.perform(*job.args)
          beanstalk_job.delete
          result
        rescue Job::Delete
          beanstalk_job.delete
        rescue Job::Release
          beanstalk_job.release
        rescue Job::Bury
          beanstalk_job.bury
        rescue Exception => e
          beanstalk_job.bury
          raise e
        end
      end
    end
  end
  
end