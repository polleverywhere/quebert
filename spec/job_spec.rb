require 'spec_helper'

describe Quebert::Job do

  before(:all) do
    Adder.backend = @q = Quebert::Backend::InProcess.new
  end

  it "shoud initialize with block" do
    expect(
      Adder.new(1,2,3){|a| a.priority = 8080 }.priority
    ).to eql(8080)
  end

  it "should perform!" do
    expect(Adder.new(1,2,3).perform!).to eql(6)
  end

  it "should perform 0 arg jobs" do
    expect(Adder.new.perform!).to eql(0)
  end

  it "should raise not implemented on base job" do
    expect {
      Job.new.perform
    }.to raise_exception(NotImplementedError)
  end

  it "should convert job to and from JSON" do
    args = [1,2,3]
    job = Adder.new(*args)
    job.queue = "foo"
    serialized = job.to_json
    unserialized = Adder.from_json(serialized)
    expect(unserialized).to be_a(Adder)
    expect(unserialized.args).to eql(args)
    expect(unserialized.queue).to eql("foo")
  end

  it "should have default MEDIUM priority" do
    expect(Job.new.priority).to eql(Quebert::Job::Priority::MEDIUM)
  end

  describe "Quebert::Job::Priority" do
    it "should have LOW priority of 4294967296" do
      expect(Quebert::Job::Priority::LOW).to eql(4294967296)
    end
    it "should have MEDIUM priority of 2147483648" do
      expect(Quebert::Job::Priority::MEDIUM).to eql(2147483648)
    end
    it "should have HIGH priority of 0" do
      expect(Quebert::Job::Priority::HIGH).to eql(0)
    end
  end

  context "actions" do
    it "should raise release" do
      expect {
        ReleaseJob.new.perform
      }.to raise_exception(Job::Release)
    end

    it "should raise delete" do
      expect {
        DeleteJob.new.perform
      }.to raise_exception(Job::Delete)
    end

    it "should raise bury" do
      expect {
        BuryJob.new.perform
      }.to raise_exception(Job::Bury)
    end
  end

  context "job queue" do
    it "should enqueue" do
      expect {
        Adder.new(1,2,3).enqueue
      }.to change(@q, :size).by(1)
    end

    context "#enqueue options" do
      let(:job){ Adder.new(1,2,3) }

      it "should enqueue with pri" do
        expect(job).to receive(:pri=).with(100)
        job.enqueue(:pri => 100)
      end

      it "should enqueue with ttr" do
        expect(job).to receive(:ttr=).with(90)
        job.enqueue(:ttr => 90)
      end

      it "should enqueue with delay" do
        expect(job).to receive(:delay=).with(80)
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
          expect(job.beanstalk_job.pri).to eql(1)
          expect(job.beanstalk_job.delay).to eql(2)
          expect(job.beanstalk_job.ttr).to eql(300 + Quebert::Backend::Beanstalk::TTR_BUFFER)
        end

        it "should enqueue and honor beanstalk options" do
          User.async(:priority => 1, :delay => 2, :ttr => 300).emailizer("somebody", nil, nil)
          job = @q.reserve
          expect(job.beanstalk_job.pri).to eql(1)
          expect(job.beanstalk_job.delay).to eql(2)
          expect(job.beanstalk_job.ttr).to eql(300 + Quebert::Backend::Beanstalk::TTR_BUFFER)
        end
      end

      describe "legacy async_send" do
        it "should enqueue and honor beanstalk options" do
          user = User.new(:first_name => "Steel")
          user.async_send(:email!, "somebody", nil, nil, :beanstalk => {:priority => 1, :delay => 2, :ttr => 300})
          job = @q.reserve
          expect(job.beanstalk_job.pri).to eql(1)
          expect(job.beanstalk_job.delay).to eql(2)
          expect(job.beanstalk_job.ttr).to eql(300 + Quebert::Backend::Beanstalk::TTR_BUFFER)
        end

        it "should enqueue and honor beanstalk options" do
          User.async_send(:emailizer, "somebody", nil, nil, :beanstalk => {:priority => 1, :delay => 2, :ttr => 300})
          job = @q.reserve
          expect(job.beanstalk_job.pri).to eql(1)
          expect(job.beanstalk_job.delay).to eql(2)
          expect(job.beanstalk_job.ttr).to eql(300 + Quebert::Backend::Beanstalk::TTR_BUFFER)
        end
      end
    end
  end

  context "Timeout" do
    it "should respect TTR option" do
      expect {
        TimeoutJob.new.perform!
      }.to raise_exception(Quebert::Job::Timeout)
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

      expect(before_jobs).to eql jobs
      expect(after_jobs).to  eql jobs
      # around_job hooks are called twice per job (before & after its performed)
      expect(around_jobs).to eql jobs.zip(jobs).flatten
    end
  end
end
