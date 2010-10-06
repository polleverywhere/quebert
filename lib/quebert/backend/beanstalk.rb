require 'beanstalk-client'

module Quebert
  module Backend
    
    # Manage jobs on a Beanstalk queue out of process
    class Beanstalk < Beanstalk::Pool
      def put(job)
        super job.to_json
      end
      
      def reserve_with_consumer
        Consumer::Beanstalk.new(reserve_without_consumer, self)
      end
      alias :reserve_without_consumer :reserve
      alias :reserve :reserve_with_consumer
      
      # For testing purposes... I think there's a better way to do this though.
      def drain!
        while peek_ready do
          reserve_without_consumer.delete
        end
        while job = peek_buried do
          last_conn.kick 1 # what? Why the 1? it kicks them all?
          reserve_without_consumer.delete
        end
      end
      
      def self.configure(opts={})
        opts[:host] ||= '127.0.0.1:11300'
        new(opts[:host], opts[:tube])
      end
    end
  end
end