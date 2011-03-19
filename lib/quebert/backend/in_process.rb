module Quebert
  module Backend
    # Drops jobs on an array in-process.
    class InProcess < Array
      def put(job, *args)
        unshift job.to_json
      end
      
      def reserve
        json = pop and Controller::Base.new(Job.from_json(json))
      end
    end
  end
end