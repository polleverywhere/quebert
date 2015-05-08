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
      backend.send(:connection).connection.host.should eql("localhost")
      backend.send(:connection).connection.port.should eql(11300)
      backend.send(:default_tube).tube.name.should eql("quebert-config-test")
    end
  end
end
