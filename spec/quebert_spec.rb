require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Quebert do
  
  it "should have configuration keys" do
    Quebert.configuration.should respond_to(:backend)
  end
end