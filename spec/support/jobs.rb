class ReleaseJob < Quebert::Job
  def perform
    release!
  end
end

class DeleteJob < Quebert::Job
  def perform
    delete!
  end
end

class BuryJob < Quebert::Job
  def perform
    bury!
  end
end

class TimeoutJob < Quebert::Job
  def initialize
    super
    @ttr = 1
  end

  def perform
    # 10 second task should definitely raise a Job::Timeout exception
    sleep(10)
  end
end

class Adder < Quebert::Job
  def perform(*args)
    args.inject(0){|sum, n| sum = sum + n}
  end
end

class Exceptional < Quebert::Job
  def perform
    fail "Exceptional"
  end
end
