module Quebert
  # The basic glue between a job and the specific queue implementation. This
  # handles exceptions that may be thrown by the Job and how the Job should
  # be put back on the queue, if at all.
  module Consumer
    autoload :Base,       'quebert/consumer/base'
    autoload :Beanstalk,  'quebert/consumer/beanstalk'
  end
end