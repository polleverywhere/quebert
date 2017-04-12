require 'spec_helper'

describe Quebert do
  it "should have configuration keys" do
    expect(Quebert.configuration).to respond_to(:backend)
  end
end
