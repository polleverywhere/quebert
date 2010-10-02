require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'active_record'

describe AsyncSender::Klass do
  
  before(:all) do
    @q = Backend::InProcess.new
  end
  
  class Greeter
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
  
  Greeter.send(:include, Quebert::AsyncSender::Klass)
  
  it "should async send class methods" do
    Quebert::AsyncSender::Klass::KlassJob.backend = @q
    
    Greeter.async_send(:hi, 'Jeannette')
    @q.reserve.perform.should eql(Greeter.send(:hi, 'Jeannette'))
  end
  
  it "should async send instance methods" do
    Quebert::AsyncSender::Klass::InstanceJob.backend = @q
    
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
  end
  
  before(:all) do
    @q = Backend::InProcess.new
    Quebert::AsyncSender::ActiveRecord::RecordJob.backend = @q
    @user = User.create!(:first_name => 'Brad', :last_name => 'Gessler', :email => 'brad@bradgessler.com')
  end
  
  it "should async_send instance method" do
    User.first.async_send(:name)
    @q.reserve.perform.should eql(User.first.name)
  end
end