require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Quebert::Job do
  
  before(:all) do
    Adder.backend = @q = Quebert::Backend::InProcess.new
  end

  it "should perform!" do
    Adder.new(1,2,3).perform!.should eql(6)
  end
  
  it "should perform 0 arg jobs" do
    Adder.new.perform!.should eql(0)
  end
  
  it "should raise not implemented on base job" do
    lambda {
      Job.new.perform
    }.should raise_exception(Quebert::Job::NotImplemented)
  end
  
  it "should convert job to and from JSON" do
    args = [1,2,3]
    serialized = Adder.new(*args).to_json
    unserialized = Adder.from_json(serialized)
    unserialized.should be_instance_of(Adder)
    unserialized.args.should eql(args)
  end
  
  context "actions" do
    it "should raise release" do
      lambda{
        ReleaseJob.new.perform
      }.should raise_exception(Job::Release)
    end
    
    it "should raise delete" do
      lambda{
        DeleteJob.new.perform
      }.should raise_exception(Job::Delete)
    end
    
    it "should raise bury" do
      lambda{
        BuryJob.new.perform
      }.should raise_exception(Job::Bury)
    end
  end
  
  context "job queue" do
    it "should enqueue" do
      lambda{
        Adder.new(1,2,3).enqueue
      }.should change(@q, :size).by(1)
    end

    context "beanstalk backend" do
      before(:all) do
        Quebert.serializers.register 'ActiveRecord::Base', Serializer::ActiveRecord

        @q = Backend::Beanstalk.new('localhost:11300','quebert-test')

        Quebert::AsyncSender::ActiveRecord::RecordJob.backend = @q
        Quebert::AsyncSender::Object::ObjectJob.backend = @q

        @q.drain!
      end

      it "should enqueue and honor beanstalk options" do
        user = User.new(:first_name => "Steel")
        user.async_send(:email, "somebody", nil, nil, :beanstalk => {:priority => 1, :delay => 2, :ttr => 300})
        job = @q.reserve
        job.beanstalk_job.pri.should eql(1)
        job.beanstalk_job.delay.should eql(2)
        job.beanstalk_job.ttr.should eql(300 + Job::QUEBERT_TTR_BUFFER)
      end

      it "should enqueue and honor beanstalk options" do
        User.async_send(:emailizer, "somebody", nil, nil, :beanstalk => {:priority => 1, :delay => 2, :ttr => 300})
        job = @q.reserve
        job.beanstalk_job.pri.should eql(1)
        job.beanstalk_job.delay.should eql(2)
        job.beanstalk_job.ttr.should eql(300 + Job::QUEBERT_TTR_BUFFER)
      end
    end
  end
  
  context "Timeout" do
    it "should respect TTR option" do
      lambda {
        TimeoutJob.new.perform!
      }.should raise_exception(Quebert::Job::Timeout)
    end
  end
end