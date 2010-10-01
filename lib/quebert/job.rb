require 'json'

module Quebert
  class Job
    attr_reader :args
    
    NotImplemented = Class.new(StandardError)
    
    Action  = Class.new(Exception)
    
    Bury    = Class.new(Action)
    Delete  = Class.new(Action)
    Release = Class.new(Action)
    
    def initialize(args=[])
      @args = args.dup.freeze
    end
    
    def perform(*args)
      raise NotImplemented
    end
    
    def self.enqueue(*args)
      queue.put(self, *args)
    end
    
    def to_json
      self.class.to_json(self)
    end
    
    def self.to_json(job, *args)
      args, job = job.args, job.class if job.respond_to?(:args)
      JSON.generate('job' => job.name, 'args' => args)
    end
    
    def self.from_json(json)
      if data = JSON.parse(json)
        Support.constantize(data['job']).new(data['args'])
      end
    end
    
    def self.queue=(queue)
      @queue = queue
    end
    def self.queue
      @queue
    end
    
  protected
    def delete!
      raise Delete
    end
    
    def release!
      raise Release
    end
    
    def bury!
      raise Bury
    end
  end
end