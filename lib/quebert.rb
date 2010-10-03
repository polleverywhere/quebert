$:.unshift File.join(File.dirname(__FILE__), 'quebert')

module Quebert
  autoload :Configuration,  'quebert/configuration'
  autoload :Job,            'quebert/job'
  autoload :Consumer,       'quebert/consumer'
  autoload :Backend,        'quebert/backend'
  autoload :Support,        'quebert/support'
  autoload :Worker,         'quebert/worker'
  autoload :Daemonizable,   'quebert/daemonizing'
  autoload :AsyncSender,    'quebert/async_sender'
  
  class << self
    def configuration
      @configuration ||= Configuration.new
    end
    alias_method :config, :configuration

    # Registry for quebert backends
    def backends
      @backends ||= {}
    end
  end
  
  # Register built-in Quebert backends
  Backend.register :beanstalk,  Backend::Beanstalk
  Backend.register :in_process, Backend::InProcess
  Backend.register :sync,       Backend::Sync
end