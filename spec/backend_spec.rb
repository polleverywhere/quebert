require 'spec_helper'

describe Backend do
  it "has register backends" do
    expect(Quebert.backends.keys).to match_array([:in_process, :beanstalk, :sync])
  end

  it "registers backends" do
    Quebert.backends.register :twenty, 20
    expect(Quebert.backends[:twenty]).to eql(20)
  end

  it "unregisters backends" do
    Quebert.backends.unregister :twenty
    expect(Quebert.backends[:twenty]).to be_nil
  end
end

describe Backend::InProcess do
  before(:all) do
    @q = Backend::InProcess.new
  end

  it "puts on queue" do
    3.times do |num|
      @q.put Adder.new(num)
    end
  end

  it "consumes from queue" do
    3.times do |num|
      expect(@q.reserve.perform).to eql(num)
    end
  end
end

describe Backend::Beanstalk  do
  before(:all) do
    @q = Backend::Beanstalk.new('localhost:11300','quebert-test')
    @q.drain!
  end

  it "puts on queue" do
    3.times do |num|
      @q.put Adder.new(num)
    end
  end

  it "consumes from queue" do
    3.times do |num|
      expect(@q.reserve.perform).to eql(num)
    end
  end

  it "consumes from multiple queues" do
    @q.queues = ["a", "b"]
    job1 = Adder.new(1)
    job1.queue = "a"
    @q.put(job1)
    job2 = Adder.new(2)
    job2.queue = "b"
    @q.put(job2)
    expect(@q.reserve.perform).to eql(1)
    expect(@q.reserve.perform).to eql(2)
  end
end

describe Backend::Sync do
  before(:all) do
    @q = Backend::Sync.new
  end

  it "puts on queue" do
    3.times do |num|
      expect(@q.put(Adder.new(num))).to eql(num)
    end
  end

  it "does nothing when consuming from queue" do
    3.times do |num|
      expect(@q.reserve.perform).to be_nil
    end
  end
end
