require 'spec_helper'

describe Support::ClassRegistry do
  Super = Class.new
  Sub   = Class.new(Super)
  
  before(:all) do
    @registry = Support::ClassRegistry.new
  end
  
  it "should store class symbols" do
    @registry[:'Super'] = Super
    @registry[:'Super'].should eql(Super)
  end
  
  it "should retrieve class keys" do
    @registry[Super].should eql(Super)
  end
  
  it "should retrieve subclass keys" do
    @registry[Sub].should eql(Super)
  end
end