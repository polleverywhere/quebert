require 'spec_helper'

describe Serializer::ActiveRecord do
  context "persisted" do
    let(:user) { User.create!(:first_name => 'Tom', :last_name => 'Jones') }

    it "should serialize" do
      h = Serializer::ActiveRecord.serialize(user)
      h['model'].should eql('User')
      h['attributes']['first_name'].should eql('Tom')
      h['attributes']['id'].should eql(user.id)
    end
    
    it "should deserialize" do
      u = Serializer::ActiveRecord.deserialize(Serializer::ActiveRecord.serialize(user))
      u.first_name.should eql('Tom')
      u.id.should eql(user.id)
    end
  end
  
  context "unpersisted" do
    let(:user) { User.new(:first_name => 'brad') }

    it "should serialize" do
      h = Serializer::ActiveRecord.serialize(user)
      h['model'].should eql('User')
      h['attributes']['first_name'].should eql('brad')
      h['attributes']['id'].should be_nil
    end
    
    it "should deserialize" do
      u = Serializer::ActiveRecord.deserialize(Serializer::ActiveRecord.serialize(user))
      u.first_name.should eql('brad')
    end
  end
end

describe Serializer::Job do
  let(:user) { User.new(:first_name => 'Brad') }
  let(:args) { [100, user] }
  let(:job)  do
    job = Job.new(*args)
    job.priority  = 1
    job.delay     = 2
    job.ttr       = 300
    job
  end
  let(:serialized)    { Serializer::Job.serialize(job) }
  let(:deserialized)  { Serializer::Job.deserialize(serialized) }

  describe "#serialize" do
    it "shold have job" do
      serialized['job'].should eql('Quebert::Job')
    end

    it "should have args" do
      serialized['args'][0]['payload'].should eql(100)
      serialized['args'][1]['payload'].should eql(Serializer::ActiveRecord.serialize(args[1]))
      serialized['args'][1]['serializer'].should eql('Quebert::Serializer::ActiveRecord')
    end

    it "should have priority" do
      serialized['priority'].should eql(1)
    end

    it "should have delay" do
      serialized['delay'].should eql(2)
    end

    it "should have ttr" do
      serialized['ttr'].should eql(300)
    end
  end

  describe "#deserialize" do
    it "should have args" do
      deserialized.args[0].should eql(100)
      deserialized.args[1].first_name.should eql('Brad')
    end

    it "should have delay" do
      deserialized.delay.should eql(2)
    end

    it "should have priority" do
      deserialized.priority.should eql(1)
    end

    it "should have ttr" do
      deserialized.ttr.should eql(300)
    end
  end
end