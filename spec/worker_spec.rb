require 'spec_helper'

describe Worker do
  before(:each) do
    @q = Backend::InProcess.new
    @w = Worker.new do |w|
      w.backend = @q
    end
  end

  it "starts" do
    @w.start
  end

  context "pluggable exception handler" do
    it "raises exception if nothing is provided" do
      @q.put Exceptional.new
      expect { @w.start }.to raise_exception(RuntimeError, "Exceptional")
    end

    it "defaults to Quebert.config.worker.exception_handler handler" do
      @q.put Exceptional.new
      Quebert.config.worker.exception_handler = Proc.new{|e, opts| expect(e).to be_a(StandardError) }
      expect { @w.start }.to_not raise_exception
    end

    it "intercepts exceptions" do
      @q.put Exceptional.new
      @w.exception_handler = Proc.new{|e, opts| expect(e).to be_a(StandardError) }
      expect { @w.start }.to_not raise_exception
    end
  end
end
