require 'spec_helper'

describe Configuration do
  context "from hash" do
    before(:all) do
      @config = Configuration.new.from_hash(
        "backend" => "beanstalk",
        "host" => "localhost:11300",
        "queue" => "quebert-config-test")
    end

    it "should configure backend" do
      backend = @config.backend
      expect(backend).to be_instance_of(Quebert::Backend::Beanstalk)
      # Blech, gross nastiness in their lib, but we need to look in to see if this stuff as configed
      expect(backend.send(:beanstalkd_connection).connection.host).to eql("localhost")
      expect(backend.send(:beanstalkd_connection).connection.port).to eql(11300)
      expect(backend.send(:default_tube).name).to eql("quebert-config-test")
    end
  end
end
