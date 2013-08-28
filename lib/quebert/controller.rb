module Quebert
  # The basic glue between a job and the specific queue implementation. This
  # handles exceptions that may be thrown by the Job and how the Job should
  # be put back on the queue, if at all.
  module Controller
    autoload :Base,           'quebert/controller/base'
    autoload :Beanstalk,      'quebert/controller/beanstalk'
    autoload :NullController, 'quebert/controller/null_controller'
  end
end
