module Quebert
  module Controller
    # The most Controller. Doesn't even accept the queue as an argument because there's nothing
    # a job can do to be rescheduled, etc.
    class Base
      attr_reader :job
      
      def initialize(job)
        @job = job
      end
      
      def perform
        begin
          job.perform!
        rescue Job::Action
          # Nothing to do chief!
        end
      end
    end
  end
end