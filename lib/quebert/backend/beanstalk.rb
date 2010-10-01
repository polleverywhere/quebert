require 'beanstalk-client'

module Quebert
  module Backend
    
    # Manage jobs on a Beanstalk queue out of process
    class Beanstalk < Beanstalk::Pool
      def put(job, *args)
        super Job.to_json(job, *args)
      end
      
      def reserve_with_consumer
        Consumer::Beanstalk.new(reserve_without_consumer, self)
      end
      alias :reserve_without_consumer :reserve
      alias :reserve :reserve_with_consumer
      
      # For testing purposes.
      def drain!
        while peek_ready do
          reserve_without_consumer.delete
        end
        while job = peek_buried do
          last_conn.kick 1 # what? Why the 1? it kicks them all?
          reserve_without_consumer.delete
        end
      end
      
    end
  end
end