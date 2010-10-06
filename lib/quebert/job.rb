require 'json'

module Quebert
  class Job
    attr_reader :args
    
    NotImplemented = Class.new(StandardError)
    
    Action  = Class.new(Exception)
    
    Bury    = Class.new(Action)
    Delete  = Class.new(Action)
    Release = Class.new(Action)
    
    def initialize(*args)
      @args = args.dup.freeze
    end
    
    def perform(*args)
      raise NotImplemented
    end
    
    # Runs the perform method that somebody else should be implementing
    def perform!
      perform(*args)
    end
    
    def enqueue
      self.class.backend.put self
    end
    
    def to_json
      JSON.generate(Serializer::Job.serialize(self))
    end
    
    def self.from_json(json)
      if hash = JSON.parse(json) and not hash.empty?
        Serializer::Job.deserialize(hash)
      end
    end
    
    def self.backend=(backend)
      @backend = backend
    end
    def self.backend
      @backend || Quebert.configuration.backend
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