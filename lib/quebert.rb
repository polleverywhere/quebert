module Quebert
  autoload :Serializer,         'quebert/serializer'
  autoload :Configuration,      'quebert/configuration'
  autoload :Job,                'quebert/job'
  autoload :Controller,         'quebert/controller'
  autoload :Backend,            'quebert/backend'
  autoload :Support,            'quebert/support'
  autoload :Worker,             'quebert/worker'
  autoload :CommandLineRunner,  'quebert/command_line_runner'
  autoload :AsyncSender,        'quebert/async_sender'
  
  class << self
    def configuration
      @configuration ||= Configuration.new
    end
    alias_method :config, :configuration

    # Registry for quebert backends
    def backends
      @backends ||= Support::Registry.new
    end
    
    def serializers
      @serializers ||= Support::ClassRegistry.new
    end
    
    # Make this easier for elsewhere in the app
    def logger
      config.logger
    end
  end
  
  # Register built-in Quebert backends
  Quebert.backends.register :beanstalk,       Backend::Beanstalk
  Quebert.backends.register :in_process,      Backend::InProcess
  Quebert.backends.register :sync,            Backend::Sync
end