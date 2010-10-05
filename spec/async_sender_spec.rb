require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'active_record'

describe AsyncSender::Class do
  
  before(:all) do
    @q = Backend::InProcess.new
    Quebert::AsyncSender::Object::ObjectJob.backend = @q
    Quebert::AsyncSender::Instance::InstanceJob.backend = @q
  end
  
  class Greeter
    include AsyncSender::Class
    
    def initialize(name)
      @name = name
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
    @q.reserve.perform.should eql(Greeter.new("brad").send(:hi, 'stunning'))
  end
  
end

describe AsyncSender::ActiveRecord do
  
  ActiveRecord::Base.establish_connection({
    :adapter => 'sqlite3',
    :database => ':memory:'
  })
  
  ActiveRecord::Schema.define do
    create_table "users", :force => true do |t|
      t.column "first_name",  :text
      t.column "last_name",  :text
      t.column "email", :text
    end
  end
  
  class User < ActiveRecord::Base
    include Quebert::AsyncSender::ActiveRecord
    
    def name
      "#{first_name} #{last_name}"
    end
    
    def self.emailizer(address)
      address
    end
  end
  
  before(:all) do
    @q = Backend::InProcess.new
    Quebert::AsyncSender::ActiveRecord::PersistedRecordJob.backend = @q
    Quebert::AsyncSender::ActiveRecord::UnpersistedRecordJob.backend = @q
    Quebert::AsyncSender::Object::ObjectJob.backend = @q
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
end