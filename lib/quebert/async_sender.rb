module Quebert
  module AsyncSender
    autoload :Object,         'quebert/async_sender/object'
    autoload :Instance,       'quebert/async_sender/instance'
    autoload :Class,          'quebert/async_sender/class'
    autoload :ActiveRecord,   'quebert/async_sender/active_record'
  end
end