require 'spec_helper'

describe Controller::Base do
  it "performs a job" do
    expect(
      Controller::Base.new(Adder.new(1,2)).perform
    ).to eql(3)
  end

  it "rescues all raised job actions" do
    [ReleaseJob, DeleteJob, BuryJob].each do |job|
      expect {
        Controller::Base.new(job.new).perform
      }.to_not raise_exception
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

  it "deletes job off queue after succesful run" do
    @q.put Adder.new(1, 2)
    expect(@q.peek(:ready)).to_not be_nil
    expect(@q.reserve.perform).to eql(3)
    expect(@q.peek(:ready)).to be_nil
  end

  it "buries job if an exception occurs in job" do
    @q.put Exceptional.new
    expect(@q.peek(:ready)).to_not be_nil
    expect { @q.reserve.perform }.to raise_exception(RuntimeError, "Exceptional")
    expect(@q.peek(:buried)).to_not be_nil
  end

  it "buries an AR job if an exception occurs deserializing it" do
    tube = @q.send(:default_tube)
    tube.put({:foo => "bar"}.to_json)
    expect(tube.peek(:ready)).to_not be_nil
    expect { @q.reserve.perform }.to raise_exception(NoMethodError)
    expect(tube.peek(:buried)).to_not be_nil
  end

  context "job actions" do
    it "deletes a job" do
      @q.put DeleteJob.new
      expect(@q.peek(:ready)).to_not be_nil
      @q.reserve.perform
      expect(@q.peek(:ready)).to be_nil
    end

    it "releases a job" do
      @q.put ReleaseJob.new
      expect(@q.peek(:ready)).to_not be_nil
      @q.reserve.perform
      expect(@q.peek(:ready)).to_not be_nil
    end

    it "buries a job" do
      @q.put BuryJob.new
      expect(@q.peek(:ready)).to_not be_nil
      expect(@q.peek(:buried)).to be_nil
      @q.reserve.perform
      expect(@q.peek(:ready)).to be_nil
      expect(@q.peek(:buried)).to_not be_nil
    end
  end

  it "retries a job with a delay and then buries it" do
    TimeoutJob.backend = @q
    TimeoutJob.new.enqueue
    expect(@q.peek(:ready)).to_not be_nil
    job = @q.reserve
    expect(job.beanstalk_job.stats["releases"]).to eql(0)
    expect(job.beanstalk_job.stats["delay"]).to eql(0)
    expect {
      job.perform
    }.to raise_exception(Quebert::Job::Timeout)

    expect(@q.peek(:ready)).to be_nil
    beanstalk_job = @q.peek(:delayed)
    expect(beanstalk_job).to_not be_nil
    expect(beanstalk_job.stats["releases"]).to eql(1)
    expect(beanstalk_job.stats["delay"]).to eql(Quebert::Controller::Beanstalk::TIMEOUT_RETRY_GROWTH_RATE**beanstalk_job.stats["releases"])

    sleep(3)

    # lets set the max retry delay so it should bury instead of delay
    redefine_constant Quebert::Controller::Beanstalk, :MAX_TIMEOUT_RETRY_DELAY, 1
    expect {
      @q.reserve.perform
    }.to raise_exception(Quebert::Job::Timeout)

    expect(@q.peek(:ready)).to be_nil
    expect(@q.peek(:delayed)).to be_nil
    expect(@q.peek(:buried)).to_not be_nil
  end
end
