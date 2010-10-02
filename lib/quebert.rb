$:.unshift File.join(File.dirname(__FILE__), 'quebert')

module Quebert
  autoload :Job,            'quebert/job'
  autoload :Consumer,       'quebert/consumer'
  autoload :Backend,        'quebert/backend'
  autoload :Support,        'quebert/support'
  autoload :Worker,         'quebert/worker'
  autoload :Daemonizable,   'quebert/daemonizing'
  autoload :AsyncSender,    'quebert/async_sender'
  
  def self.configuration
    @configuration ||= Struct.new(:backend).new
  end
end