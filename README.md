# Quebert

[![Build Status](https://travis-ci.org/polleverywhere/quebert.png?branch=master)](https://travis-ci.org/polleverywhere/quebert)

async_observer is great, but is dated and doesn't really support running jobs outside of the async_send idiom. Quebert is an attempt to mix how jobs are run in other popular worker queue frameworks, like resque and dj, with async_observer so that you can have it both ways.

# Why Quebert (or how is it different from DJ and Resque)?

Because it has really low latency. Other Ruby queuing frameworks, like DJ or Resque, have to poll their queue servers periodicly. You could think of it as a "pull" queue. Quebert is a "push" queue. It maintains a persistent connection with beanstalkd and when is enqueud, its instantly pushed to the workers and executed.

# Who uses it?

Quebert is a serious project. Its used in a production environment at Poll Everywhere to handle everything from SMS message processing to account downgrades.

# Features

* Multiple back-ends (InProcess, Sync, and Beanstalk)
* Rails/ActiveRecord integration similar to async_observer
* Pluggable exception handling (for Hoptoad integration)
* Run workers with pid, log, and config files. These do not daemonize (do it yourself punk!)

Some features that are currently missing that I will soon add include:

* Rails plugin support (The AR integrations have to be done manually today)
* Auto-detecting serializers. Enhanced ClassRegistry to more efficiently look up serializers for objects.

# How to use

There are two ways to enqueue jobs with Quebert: through the Job itself, provided you set a default back-end for the job, or put it on the backend.

## Jobs

Quebert includes a Job class so you can implement how you want certain types of Jobs performed.
    
    Quebert.backend = Quebert::Backend::InProcess.new
    
    class WackyMathWizard < Quebert::Job
      def perform(*nums)
        nums.inject(0){|sum, n| sum = sum + n}
      end
    end

You can either drop a job in a queue:

    Quebert.backend.put WackyMathWizard.new(1, 2, 3)

Or drop it in right from the job:

    WackyMathWizard.new(4, 5, 6).enqueue

Then perform the jobs!

    Quebert.backend.reserve.perform # => 6
    Quebert.backend.reserve.perform # => 15

## Async Sender

Take any ol' class and include the Quebert::AsyncSender.

    Quebert.backend = Quebert::Backend::InProcess.new

    class Greeter
      include Quebert::AsyncSender::Class
      
      def initialize(name)
        @name = name
      end
      
      def sleep_and_greet(time_of_day)
        sleep 10000 # Sleeping, get it?
        "Oh! Hi #{name}! Good #{time_of_day}."
      end
      
      def self.budweiser_greeting(name)
        "waaazup #{name}!"
      end
    end
    
    walmart_greeter = Greeter.new("Brad")

Remember the send method in ruby?

    walmart_greeter.send(:sleep_and_greet, "morning")
    # ... time passes, you wait as greeter snores obnoxiously ...
    # => "Oh! Hi Brad! Good morning."

What if the method takes a long time to run and you want to queue it? async.send it!

    walmart_greeter.async.sleep_and_greet("morning")
    # ... do some shopping and come back later when the dude wakes up
    
Quebert figures out how to *serialize the class, throw it on a worker queue, re-instantiate it on the other side, and finish up the work.

    Quebert.backend.reserve.perform # => "Oh! Hi Brad! Good morning."
    # ... Sorry dude! I'm shopping already
    
Does it work on Class methods? Yeah, that was easier than making instance methods work:

    Quebert.async.budweiser_greeting("Corey")
    Quebert.backend.reserve.perform # => "waazup Corey!"

* Only basic data types are included for serialization. Serializers may be customized to include support for different types.
