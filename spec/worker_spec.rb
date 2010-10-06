require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Worker do
  before(:each) do
    @q = Backend::InProcess.new
    @w = Worker.new do |w|
      w.backend = @q
    end
  end
  
  it "should start" do
    @w.start
  end
  
  context "pluggable exception handler" do
    it "should raise exception if nothing is provided" do
      @q.put Exceptional.new
      lambda{ @w.start }.should raise_exception
    end

    it "should default to Quebert.config.worker.exception_handler handler" do
      @q.put Exceptional.new
      Quebert.config.worker.exception_handler = Proc.new{|e| e.should be_instance_of(Exception) }
      @w.exception_handler = Proc.new{|e| e.should be_instance_of(Exception) }
      lambda{ @w.start }.should_not raise_exception
    end
    
    it "should intercept exceptions" do
      @q.put Exceptional.new
      @w.exception_handler = Proc.new{|e| e.should be_instance_of(Exception) }
      lambda{ @w.start }.should_not raise_exception
    end
  end
end