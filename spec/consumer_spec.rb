require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'ruby-debug'

describe Consumer::Base do
  it "should perform job" do
    Consumer::Base.new(Adder.new([1,2])).perform.should eql(3)
  end
  
  it "should rescue all raised job actions" do
    [ReleaseJob, DeleteJob, BuryJob].each do |job|
      lambda{
        Consumer::Base.new(job.new).perform
      }.should_not raise_exception
    end
  end
end

describe Consumer::Beanstalk do
  before(:all) do
    @q = Backend::Beanstalk.new(['localhost:11300'], 'quebert-test-jobs-actions')
  end
  
  before(:each) do
    @q.drain!
  end
  
  it "should delete job off queue after succesful run" do
    @q.put(Adder, 1, 2)
    @q.peek_ready.should_not be_nil
    @q.reserve.perform.should eql(3)
    @q.peek_ready.should be_nil
  end
  
  it "should bury job if an exception occurs in job" do
    @q.put Exceptional
    @q.peek_ready.should_not be_nil
    lambda{ @q.reserve.perform }.should raise_exception
    @q.peek_buried.should_not be_nil
  end
  
  context "job actions" do
    it "should delete job" do
      @q.put DeleteJob
      @q.peek_ready.should_not be_nil
      @q.reserve.perform
      @q.peek_ready.should be_nil
    end
    
    it "should release job" do
      @q.put ReleaseJob
      @q.peek_ready.should_not be_nil
      @q.reserve.perform
      @q.peek_ready.should_not be_nil
    end
    
    it "should bury job" do
      @q.put BuryJob
      @q.peek_ready.should_not be_nil
      @q.peek_buried.should be_nil
      @q.reserve.perform
      @q.peek_ready.should be_nil
      @q.peek_buried.should_not be_nil
    end
  end
end