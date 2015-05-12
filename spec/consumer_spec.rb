require 'spec_helper'

describe Controller::Base do
  it "should perform job" do
    Controller::Base.new(Adder.new(1,2)).perform.should eql(3)
  end

  it "should rescue all raised job actions" do
    [ReleaseJob, DeleteJob, BuryJob].each do |job|
      lambda{
        Controller::Base.new(job.new).perform
      }.should_not raise_exception
    end
  end
end

describe Controller::Beanstalk do
  before(:all) do
    @q = Backend::Beanstalk.configure(:host => "localhost:11300",
      :queue => "quebert-test-jobs-actions")
  end

  before(:each) do
    @q.drain!
  end

  it "should delete job off queue after succesful run" do
    @q.put Adder.new(1, 2)
    @q.peek(:ready).should_not be_nil
    @q.reserve.perform.should eql(3)
    @q.peek(:ready).should be_nil
  end

  it "should bury job if an exception occurs in job" do
    @q.put Exceptional.new
    @q.peek(:ready).should_not be_nil
    lambda{ @q.reserve.perform }.should raise_exception
    @q.peek(:buried).should_not be_nil
  end

  it "should bury an AR job if an exception occurs deserializing it" do
    tube = @q.send(:default_tube)
    tube.put({:foo => "bar"}.to_json)
    tube.peek(:ready).should_not be_nil
    lambda{ @q.reserve.perform }.should raise_exception
    tube.peek(:buried).should_not be_nil
  end

  context "job actions" do
    it "should delete job" do
      @q.put DeleteJob.new
      @q.peek(:ready).should_not be_nil
      @q.reserve.perform
      @q.peek(:ready).should be_nil
    end

    it "should release job" do
      @q.put ReleaseJob.new
      @q.peek(:ready).should_not be_nil
      @q.reserve.perform
      @q.peek(:ready).should_not be_nil
    end

    it "should bury job" do
      @q.put BuryJob.new
      @q.peek(:ready).should_not be_nil
      @q.peek(:buried).should be_nil
      @q.reserve.perform
      @q.peek(:ready).should be_nil
      @q.peek(:buried).should_not be_nil
    end
  end

  it "should retry a job with a delay and then bury" do
    TimeoutJob.backend = @q
    TimeoutJob.new.enqueue
    @q.peek(:ready).should_not be_nil
    job = @q.reserve
    job.beanstalk_job.stats["releases"].should eql(0)
    job.beanstalk_job.stats["delay"].should eql(0)
    lambda{job.perform}.should raise_exception(Quebert::Job::Timeout)

    @q.peek(:ready).should be_nil
    beanstalk_job = @q.peek(:delayed)
    beanstalk_job.should_not be_nil
    beanstalk_job.stats["releases"].should eql(1)
    beanstalk_job.stats["delay"].should eql(Quebert::Controller::Beanstalk::TIMEOUT_RETRY_GROWTH_RATE**beanstalk_job.stats["releases"])

    sleep(3)

    # lets set the max retry delay so it should bury instead of delay
    redefine_constant Quebert::Controller::Beanstalk, :MAX_TIMEOUT_RETRY_DELAY, 1
    lambda{@q.reserve.perform}.should raise_exception(Quebert::Job::Timeout)

    @q.peek(:ready).should be_nil
    @q.peek(:delayed).should be_nil
    @q.peek(:buried).should_not be_nil
  end
end
