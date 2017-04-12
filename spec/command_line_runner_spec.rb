require 'spec_helper'

describe CommandLineRunner do
  before(:all) do
    Quebert.config.backend = Backend::InProcess.new
  end

  context "log-file" do
    it "writes log file" do
      clean_file 'log.log' do
        expect {
          CommandLineRunner.dispatch(%w(worker --log log.log))
        }.to change { File.read('log.log') if File.exists?('log.log') }
      end
    end
  end

  context "pid-file" do
    it "writes pid" do
      clean_file 'pid.pid' do
        expect(File.exists?('pid')).to be_falsey
        CommandLineRunner.dispatch(%w(worker --pid pid.pid))
        expect(Support::PidFile.read('pid.pid')).to eql(Process.pid)
      end
    end

    it "removes stale" do
      clean_file 'pid.pid', "-1" do
        CommandLineRunner.dispatch(%w(worker --pid pid.pid))
        expect(Support::PidFile.read('pid.pid')).to eql(Process.pid)
      end
    end

    it "complains if the pid is already running" do
      clean_file 'pid.pid', Process.pid do
        expect {
          CommandLineRunner.dispatch(%w(worker --pid pid.pid))
        }.to raise_exception(Support::PidFile::ProcessRunning)
        expect(Support::PidFile.read('pid.pid')).to eql(Process.pid)
      end
    end
  end

  context "config-file" do
    it "auto-detects rails environment file" do
      clean_file './config/environment.rb', "raise 'RailsConfig'" do
        expect {
          CommandLineRunner.dispatch(%w(worker))
        }.to raise_exception('RailsConfig')
      end
    end

    it "runs config file" do
      clean_file './super_awesome.rb', "raise 'SuperAwesome'" do
        expect {
          CommandLineRunner.dispatch(%w(worker --config ./super_awesome.rb))
        }.to raise_exception('SuperAwesome')
      end
    end

  end

  context "chdir" do
    before(:each) do
      @chdir = Dir.pwd
    end

    it "changes chdir" do
      CommandLineRunner.dispatch(%w(worker --chdir /))
      expect(Dir.pwd).to eql('/')
    end

    after(:each) do
      Dir.chdir(@chdir)
    end
  end
end
