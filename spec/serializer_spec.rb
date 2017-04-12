require 'spec_helper'

describe Serializer::ActiveRecord do
  context "persisted" do
    let(:user) { User.create!(:first_name => 'Tom', :last_name => 'Jones') }

    it "should serialize" do
      h = Serializer::ActiveRecord.serialize(user)
      expect(h['model']).to eql('User')
      expect(h['attributes']['first_name']).to eql('Tom')
      expect(h['attributes']['id']).to eql(user.id)
    end

    it "should deserialize" do
      u = Serializer::ActiveRecord.deserialize(Serializer::ActiveRecord.serialize(user))
      expect(u.first_name).to eql('Tom')
      expect(u.id).to eql(user.id)
    end
  end

  context "unpersisted" do
    let(:user) { User.new(:first_name => 'brad') }

    it "should serialize" do
      h = Serializer::ActiveRecord.serialize(user)
      expect(h['model']).to eql('User')
      expect(h['attributes']['first_name']).to eql('brad')
      expect(h['attributes']['id']).to be_nil
    end

    it "should deserialize" do
      u = Serializer::ActiveRecord.deserialize(Serializer::ActiveRecord.serialize(user))
      expect(u.first_name).to eql('brad')
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
      expect(serialized['job']).to eql('Quebert::Job')
    end

    it "should have args" do
      expect(serialized['args'][0]['payload']).to eql(100)
      expect(serialized['args'][1]['payload']).to eql(Serializer::ActiveRecord.serialize(args[1]))
      expect(serialized['args'][1]['serializer']).to eql('Quebert::Serializer::ActiveRecord')
    end

    it "should have priority" do
      expect(serialized['priority']).to eql(1)
    end

    it "should have delay" do
      expect(serialized['delay']).to eql(2)
    end

    it "should have ttr" do
      expect(serialized['ttr']).to eql(300)
    end
  end

  describe "#deserialize" do
    it "should have args" do
      expect(deserialized.args[0]).to eql(100)
      expect(deserialized.args[1].first_name).to eql('Brad')
    end

    it "should have delay" do
      expect(deserialized.delay).to eql(2)
    end

    it "should have priority" do
      expect(deserialized.priority).to eql(1)
    end

    it "should have ttr" do
      expect(deserialized.ttr).to eql(300)
    end
  end
end
