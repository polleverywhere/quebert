require 'logger'

module Quebert
  class Configuration
    attr_accessor :backend, :logger, :worker
    
    def logger
      @logger ||= begin
        l = Logger.new($stdout)
        l.formatter = Logger::Formatter.new
        l
      end
    end
    
    def log_file_path=(path)
      self.logger = begin
        l = Logger.new(path)
        l.formatter = Logger::Formatter.new
        l
      end
    end
    
    def from_hash(hash)
      hash = Support.symbolize_keys(hash)
      # Find out backend from the registry and configure
      if backend = Quebert.backends[hash.delete(:backend).to_sym]
        # If the backend supports configuration, do it!
        self.backend = backend.respond_to?(:configure) ? backend.configure(Support.symbolize_keys(hash)) : backend.new
      end
      self
    end

    def worker
      @worker ||= Struct.new(:exception_handler).new
    end

    def self.from_hash(hash)
      new.from_hash(hash) # Config this puppy up from a config hash
    end

    def before_job(job = nil, &block)
      if job
        before_hooks.each do |h|
          h.call(job)
        end
      else
        before_hooks << block if block
      end
      self
    end

    def after_job(job = nil, &block)
      if job
        after_hooks.each do |h|
          h.call(job)
        end
      else
        after_hooks << block if block
      end
      self
    end

    def around_job(job = nil, &block)
      if job
        around_hooks.each do |h|
          h.call(job)
        end
      else
        around_hooks << block if block
      end
      self
    end

    private

    def before_hooks
      @before_hooks ||= []
    end

    def after_hooks
      @after_hooks ||= []
    end

    def around_hooks
      @around_hooks ||= []
    end
  end
end