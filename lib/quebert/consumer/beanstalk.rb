module Quebert
  module Consumer
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