require 'spec_helper'

describe Quebert::Job do
  
  before(:all) do
    Adder.backend = @q = Quebert::Backend::InProcess.new
  end

  it "shoud initialize with block" do
    Adder.new(1,2,3){|a| a.priority = 8080 }.priority.should == 8080
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

  it "should have default MEDIUM priority" do
    Job.new.priority.should == Quebert::Job::Priority::MEDIUM
  end

  describe "Quebert::Job::Priority" do
    it "should have LOW priority of 4294967296" do
      Quebert::Job::Priority::LOW.should == 4294967296
    end
    it "should have MEDIUM priority of 2147483648" do
      Quebert::Job::Priority::MEDIUM.should == 2147483648
    end
    it "should have HIGH priority of 0" do
      Quebert::Job::Priority::HIGH.should == 0
    end
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

    context "#enqueue options" do
      let(:job){ Adder.new(1,2,3) }

      it "should enqueue with pri" do
        job.should_receive(:pri=).with(100)
        job.enqueue(:pri => 100)
      end

      it "should enqueue with ttr" do
        job.should_receive(:ttr=).with(90)
        job.enqueue(:ttr => 90)
      end

      it "should enqueue with delay" do
        job.should_receive(:delay=).with(80)
        job.enqueue(:delay => 80)
      end
    end

    context "beanstalk backend" do
      before(:all) do
        Quebert.serializers.register 'ActiveRecord::Base', Serializer::ActiveRecord

        @q = Backend::Beanstalk.new('localhost:11300','quebert-test')

        Quebert::AsyncSender::ActiveRecord::RecordJob.backend = @q
        Quebert::AsyncSender::Object::ObjectJob.backend = @q

        @q.drain!
      end

      describe "async promise DSL" do
        it "should enqueue and honor beanstalk options" do
          user = User.new(:first_name => "Steel")
          user.async(:priority => 1, :delay => 2, :ttr => 300).email!("somebody", nil, nil)
          job = @q.reserve
          job.beanstalk_job.pri.should eql(1)
          job.beanstalk_job.delay.should eql(2)
          job.beanstalk_job.ttr.should eql(300 + Job::QUEBERT_TTR_BUFFER)
        end

        it "should enqueue and honor beanstalk options" do
          User.async(:priority => 1, :delay => 2, :ttr => 300).emailizer("somebody", nil, nil)
          job = @q.reserve
          job.beanstalk_job.pri.should eql(1)
          job.beanstalk_job.delay.should eql(2)
          job.beanstalk_job.ttr.should eql(300 + Job::QUEBERT_TTR_BUFFER)
        end
      end

      describe "legacy async_send" do
        it "should enqueue and honor beanstalk options" do
          user = User.new(:first_name => "Steel")
          user.async_send(:email!, "somebody", nil, nil, :beanstalk => {:priority => 1, :delay => 2, :ttr => 300})
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
  end
  
  context "Timeout" do
    it "should respect TTR option" do
      lambda {
        TimeoutJob.new.perform!
      }.should raise_exception(Quebert::Job::Timeout)
    end
  end

  context "before, after & around hooks" do
    it "should call each type of hook as expected" do
      before_jobs = []
      after_jobs  = []
      around_jobs = []

      jobs = (1..10).map do |i|
        Adder.new(i, i)
      end

      Quebert.config.before_job do |job|
        before_jobs << job
      end

      Quebert.config.after_job do |job|
        after_jobs << job
      end

      Quebert.config.around_job do |job|
        around_jobs << job
      end

      jobs.each(&:perform!)

      before_jobs.should eql jobs
      after_jobs.should  eql jobs
      # around_job hooks are called twice per job (before & after its performed)
      around_jobs.should eql jobs.zip(jobs).flatten
    end
  end
end
