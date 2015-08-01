# Quebert

[![Build Status](https://travis-ci.org/polleverywhere/quebert.png?branch=master)](https://travis-ci.org/polleverywhere/quebert) [![Code Climate](https://codeclimate.com/repos/555266fc6956805b9e0033b5/badges/008e51483e8e268f21db/gpa.svg)](https://codeclimate.com/repos/555266fc6956805b9e0033b5/feed)

Quebert is a ruby background worker library that works with the very fast and simple [beanstalkd](http://kr.github.io/beanstalkd/) deamon.

# Why Quebert?

Because it has really low latency. Other Ruby queuing frameworks, like [DJ](https://github.com/collectiveidea/delayed_job) or [Resque](https://github.com/resque/resque), have to poll their queue servers periodicly. You could think of it as a "pull" queue. Quebert is a "push" queue. It maintains a persistent connection with beanstalkd and when is enqueud, its instantly pushed to the workers and executed.

[Sidekiq](http://sidekiq.org) uses Redis's "push" primitives so it has low latency, but it doesn't support class reloading in a development environment. Sidekiq is also threaded, which means there are no garauntees of reliability when running non-threadsafe code.

[Backburner](https://github.com/nesquena/backburner) is very similar to Quebert. It offers more options for concurrency (threading, forking, etc.) than queubert but lacks pluggable back-ends, which means you'll be stubbing and mocking async calls.

# Who uses it?

Quebert is a serious project. Its used in a production environment at [Poll Everywhere](https://www.polleverywhere.com/) to handle everything from SMS message processing to account downgrades.

# Features

* Multiple back-ends (InProcess, Sync, and Beanstalk)
* Rails/ActiveRecord integration similar to async_observer
* Pluggable exception handling (for Hoptoad integration)
* Run workers with pid, log, and config files. These do not daemonize (do it yourself punk!)
* Provide custom hooks to be called before, after & around jobs are run

Some features that are currently missing that I will soon add include:

* Rails plugin support (The AR integrations have to be done manually today)
* Auto-detecting serializers. Enhanced ClassRegistry to more efficiently look up serializers for objects.

# How to use

There are two ways to enqueue jobs with Quebert: through the Job itself, provided you set a default back-end for the job, or put it on the backend.

## Jobs

Quebert includes a Job class so you can implement how you want certain types of Jobs performed.

```ruby
Quebert.backend = Quebert::Backend::InProcess.new

class WackyMathWizard < Quebert::Job
  def perform(*nums)
    nums.inject(0){|sum, n| sum = sum + n}
  end
end
```

You can either drop a job in a queue:

```ruby
Quebert.backend.put WackyMathWizard.new(1, 2, 3)
```

Or drop it in right from the job:

```ruby
# Run job right away!
WackyMathWizard.new(4, 5, 6).enqueue
# Run a lower priority job in 10 seconds for a max of 120 seconds
WackyMathWizard.new(10, 10, 10).enqueue(ttr: 120, priority: 100, delay: 10)
```

Then perform the jobs!

```ruby
Quebert.backend.reserve.perform # => 6
Quebert.backend.reserve.perform # => 15
Quebert.backend.reserve.perform # => 30
```

## Rails integration

config/quebert.yml:

```yaml
development:
  backend: beanstalk
  host: localhost:11300
  queue: myapp-development
test:
  backend: sync
# etc.
```

config/initializers/quebert.rb:

```ruby
Quebert.config.from_hash(Rails.application.config.quebert)
Quebert.config.logger = Rails.logger
```

## Before/After/Around Hooks

Quebert has support for providing custom hooks to be called before, after & around your jobs are being run.
A common example is making sure that any active ActiveRecord database connections are put back on the connection pool after a job is done:

```ruby
Quebert.config.after_job do
  ActiveRecord::Base.clear_active_connections!
end

Quebert.config.before_job do |job|
  # all hooks take an optional job argument
  # in case you want to do something with that job
end

Quebert.config.around_job do |job|
  # this hook gets called twice
  # once before & once after a job is performed
end
```

## Async Sender

Take any ol' class and include the Quebert::AsyncSender.

```ruby
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
```

Remember the send method in ruby?

```ruby
walmart_greeter.send(:sleep_and_greet, "morning")
# ... time passes, you wait as greeter snores obnoxiously ...
# => "Oh! Hi Brad! Good morning."
```

What if the method takes a long time to run and you want to queue it? async.send it!

```ruby
walmart_greeter.async.sleep_and_greet("morning")
# ... do some shopping and come back later when the dude wakes up
```

Quebert figures out how to serialize the class, throw it on a worker queue, re-instantiate it on the other side, and finish up the work.

```ruby
Quebert.backend.reserve.perform # => "Oh! Hi Brad! Good morning."
# ... Sorry dude! I'm shopping already
```

Does it work on Class methods? Yeah, that was easier than making instance methods work:

```ruby
Quebert.async.budweiser_greeting("Coraline")
Quebert.backend.reserve.perform # => "waazup Coraline!"
```

* Only basic data types are included for serialization. Serializers may be customized to include support for different types.

## Backends

* Beanstalk: Enqueue jobs in a beanstalkd service. The workers run in a separate process. Typically used in production environments.
* Sync: Perform jobs immediately upon enqueuing. Typically used in testing environments.
* InProcess: Enqueue jobs in an in-memory array. A worker will need to reserve a job to perform.

## Using multiple queues

To start a worker pointed at a non-default queue (e.g., a Quebert "tube"), start the process with `-q`:

```sh
bundle exec quebert -q other-tube
```

Then specify the queue name in your job:

```ruby
class FooJob < Quebert::Job
  def queue
    "other-tube"
  end

  def perform(args)
    # ...
  end
end
```

## Overriding other job defaults

A `Quebert::Job` is a Plain Ol' Ruby Object. The defaults of a job, including its `ttr`, `queue_name`, and `delay` may be overridden in a super class as follows:

```ruby
# Assuming you're in Rails or using ActiveSupport
class FooJob < Quebert::Job
  def ttr
    5.minutes
  end

  def delay
    30.seconds
  end

  def queue_name
    "long-running-delayed-jobs"
  end

  def perform(args)
    # ...
  end
end
```

Take a look at the [`Quebert::Job` class](https://github.com/polleverywhere/quebert/blob/master/lib/quebert/job.rb) code for more details on methods you may ovveride.
