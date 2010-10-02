module Quebert
  module Backend
    # Drops jobs on an array in-process.
    class InProcess < Array
      def put(job, *args)
        unshift Job.to_json(job, *args)
      end
      
      def reserve
        json = pop and Consumer::Base.new(Job.from_json(json))
      end
    end
  end
end