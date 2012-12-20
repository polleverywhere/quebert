require 'spec_helper'

describe Configuration do
  context "from hash" do
    before(:all) do
      @config = Configuration.new.from_hash('backend' => 'beanstalk', 'host' => 'localhost:11300', 'tube' => 'quebert-config-test')
    end
    
    it "should configure backend" do
      backend = @config.backend
      backend.should be_instance_of(Quebert::Backend::Beanstalk)
      # Blech, gross nastiness in their lib, but we need to look in to see if this stuff as configed
      pool = backend.instance_variable_get('@pool')
      pool.connections.first.address.should eql('localhost:11300')
      tube = backend.instance_variable_get('@tube')
      tube.name.should eql('quebert-config-test')
    end
    
  end
end