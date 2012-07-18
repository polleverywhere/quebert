require 'spec_helper'

describe AsyncSender::Class do
  
  before(:all) do
    @q = Quebert::Backend::InProcess.new
    Quebert::AsyncSender::Object::ObjectJob.backend = @q
    Quebert::AsyncSender::Instance::InstanceJob.backend = @q
  end
  
  class Greeter
    include AsyncSender::Class
    
    attr_accessor :age

    def initialize(name)
      @name = name
      yield self if block_given?
    end
    
    def hi(desc)
      "hi #{@name}, you look #{desc}"
    end
    
    def self.hi(name)
      "hi #{name}!"
    end
  end

  it "should async send class methods" do
    Greeter.async_send(:hi, 'Jeannette')
    @q.reserve.perform.should eql(Greeter.send(:hi, 'Jeannette'))
  end
  
  it "should async send instance methods" do
    Greeter.new("brad").async_send(:hi, 'stunning')
    @q.reserve.perform.should eql(Greeter.new("brad").hi('stunning'))
  end

  it "should preserve class initialization if class accepts a block" do
    g = Greeter.new("brad"){|g| g.age = "57"}
    g.age.should eql("57")
  end

end

describe AsyncSender::ActiveRecord do
  
  before(:all) do
    Quebert.serializers.register :'ActiveRecord::Base', Serializer::ActiveRecord
    
    @q = Backend::InProcess.new
    Quebert::AsyncSender::ActiveRecord::RecordJob.backend = @q
    Quebert::AsyncSender::Object::ObjectJob.backend = @q
  end
  
  after(:all) do
    Quebert.serializers.unregister :'ActiveRecord::Base'
  end
  
  context "persisted" do
    before(:each) do
      @user = User.create!(:first_name => 'Brad', :last_name => 'Gessler', :email => 'brad@bradgessler.com')
    end
    
    it "should async_send instance method" do
      User.first.async_send(:name)
      @q.reserve.perform.should eql(User.first.name)
    end
  end
  
  context "unpersisted" do
    it "should async_send instance method" do
      user = User.new do |u|
        u.email = 'barf@jones.com'
        u.first_name = "Barf"
        u.send(:write_attribute, :last_name, "Jones")
      end
      user.async_send(:name)
      @q.reserve.perform.should eql("Barf Jones")
    end
  end
  
  it "should async_send class method" do
    email = "brad@bradgessler.com"
    User.async_send(:emailizer, email)
    @q.reserve.perform.should eql(email)
  end
  
  it "should async_send and successfully serialize param object" do
    user = User.new(:first_name => 'Brad')
    user2 = User.new(:first_name => 'Steel')
    user.async_send(:email, user2)
    @q.reserve.perform.first_name.should eql('Steel')
  end
end