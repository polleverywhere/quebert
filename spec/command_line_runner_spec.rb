require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CommandLineRunner do
  before(:all) do
    Quebert.config.backend = Backend::InProcess.new
  end
  
  context "log-file" do
    it "should write log file" do
      clean_file 'log.log' do
        lambda{
          CommandLineRunner.dispatch(%w(worker --log log.log))
        }.should change { File.read('log.log') if File.exists?('log.log') }
      end
    end
  end
  
  context "pid-file" do
    it "should write pid" do
      clean_file 'pid.pid' do
        File.exists?('pid').should be_false
        CommandLineRunner.dispatch(%w(worker --pid pid.pid))
        Support::PidFile.read('pid.pid').should eql(Process.pid)
      end
    end
    
    it "should remove stale" do
      clean_file 'pid.pid', "-1" do
        CommandLineRunner.dispatch(%w(worker --pid pid.pid))
        Support::PidFile.read('pid.pid').should eql(Process.pid)
      end
    end
    
    it "should complain if the pid is already running" do
      clean_file 'pid.pid', Process.pid do
        lambda{
          CommandLineRunner.dispatch(%w(worker --pid pid.pid))
        }.should raise_exception(Support::PidFile::ProcessRunning)
        Support::PidFile.read('pid.pid').should eql(Process.pid)
      end
    end
  end
  
  context "config-file" do
    it "should auto-detect rails environment file" do
      clean_file './config/environment.rb', "raise 'RailsConfig'" do
        lambda{
          CommandLineRunner.dispatch(%w(worker))
        }.should raise_exception('RailsConfig')
      end
    end
    
    it "should run config file" do
      clean_file './super_awesome.rb', "raise 'SuperAwesome'" do
        lambda{
          CommandLineRunner.dispatch(%w(worker --config super_awesome.rb))
        }.should raise_exception('SuperAwesome')
      end
    end
    
  end
  
  context "chdir" do
    before(:each) do
      @chdir = Dir.pwd
    end
    
    it "should change chdir" do
      CommandLineRunner.dispatch(%w(worker --chdir /))
      Dir.pwd.should eql('/')
    end
    
    after(:each) do
      Dir.chdir(@chdir)
    end
  end
end