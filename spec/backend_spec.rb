require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Backend do
  it "should have register backends" do
    Quebert.backends.keys.should include(:in_process, :beanstalk, :sync)
  end
  
  it "should register backends" do
    Quebert.backends.register :twenty, 20
    Quebert.backends[:twenty].should eql(20)
  end
  
  it "should unregister backends" do
    Quebert.backends.unregister :twenty
    Quebert.backends[:twenty].should be_nil
  end
end

describe Backend::InProcess do
  before(:all) do
    @q = Backend::InProcess.new
  end
  
  it "should put on queue" do
    3.times do |num|
      @q.put Adder, num
    end
  end
  
  it "should consume from queue" do
    3.times do |num|
      @q.reserve.perform.should eql(num)
    end
  end
end

describe Backend::Beanstalk  do
  before(:all) do
    @q = Backend::Beanstalk.new('localhost:11300','quebert-test')
    @q.drain!
  end
  
  it "should put on queue" do
    3.times do |num|
      @q.put Adder, num
    end
  end
  
  it "should consume from queue" do
    3.times do |num|
      @q.reserve.perform.should eql(num)
    end
  end
end


describe Backend::Sync do
  before(:all) do
    @q = Backend::Sync.new
  end
  
  it "should put on queue" do
    3.times do |num|
      @q.put(Adder, num).should eql(num)
    end
  end
  
  it "should consume from queue" do
    3.times do |num|
      lambda{
        @q.reserve.perform.should eql(num)
      }.should raise_exception
    end
  end
end