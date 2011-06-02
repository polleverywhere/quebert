module Quebert
  module Controller
    # Handle interactions between a job and a Beanstalk queue.
    class Beanstalk < Base
      attr_reader :beanstalk_job, :queue, :job
      
      def initialize(beanstalk_job, queue)
        @beanstalk_job, @queue = beanstalk_job, queue

        begin
          @job = Job.from_json(beanstalk_job.body)
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
      
      def perform
        begin
          result = job.perform!
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