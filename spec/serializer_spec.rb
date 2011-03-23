require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Serializer::ActiveRecord do
  context "persisted" do
    before(:all) do
      @user = User.create!(:first_name => 'Tom', :last_name => 'Jones')
    end
    
    it "should serialize" do
      h = Serializer::ActiveRecord.serialize(@user)
      h['model'].should eql('User')
      h['attributes']['first_name'].should eql('Tom')
      h['attributes']['id'].should eql(@user.id)
    end
    
    it "should deserialize" do
      u = Serializer::ActiveRecord.deserialize(Serializer::ActiveRecord.serialize(@user))
      u.first_name.should eql('Tom')
      u.id.should eql(@user.id)
    end
  end
  
  context "unpersisted" do
    before(:all) do
      @user = User.new(:first_name => 'brad')
    end
    
    it "should serialize" do
      h = Serializer::ActiveRecord.serialize(@user)
      h['model'].should eql('User')
      h['attributes']['first_name'].should eql('brad')
      h['attributes']['id'].should be_nil
    end
    
    it "should deserialize" do
      u = Serializer::ActiveRecord.deserialize(Serializer::ActiveRecord.serialize(@user))
      u.first_name.should eql('brad')
    end
  end
end

describe Serializer::Job do
  before(:all) do
    @args = [100, User.new(:first_name => 'Brad'), {:beanstalk => {:priority => 1, :delay => 2, :ttr => 300}}]
    @job = Job.new(*@args)
  end
  
  it "should serialize job" do
    h = Serializer::Job.serialize(@job)
    h['job'].should eql('Quebert::Job')
    h['args'][0]['payload'].should eql(100)
    h['args'][1]['payload'].should eql(Serializer::ActiveRecord.serialize(@args[1]))
    h['args'][1]['serializer'].should eql('Quebert::Serializer::ActiveRecord')
    h['priority'].should eql(1)
    h['delay'].should eql(2)
    h['ttr'].should eql(300)
  end
  
  it "should deserialize job" do
    job = Serializer::Job.deserialize(Serializer::Job.serialize(@job))
    job.args[0].should eql(100)
    job.args[1].first_name.should eql('Brad')
    job.delay.should eql(2)
    job.priority.should eql(1)
    job.ttr.should eql(300)
  end
end