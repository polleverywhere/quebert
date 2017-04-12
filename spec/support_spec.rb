require 'spec_helper'

describe Support::ClassRegistry do
  Super = Class.new
  Sub   = Class.new(Super)

  before(:all) do
    @registry = Support::ClassRegistry.new
  end

  it "should store class symbols" do
    @registry[:'Super'] = Super
    expect(@registry[:'Super']).to eql(Super)
  end

  it "should retrieve class keys" do
    expect(@registry[Super]).to eql(Super)
  end

  it "should retrieve subclass keys" do
    expect(@registry[Sub]).to eql(Super)
  end
end
