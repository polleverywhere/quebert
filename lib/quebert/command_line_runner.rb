require 'optitron'

module Quebert
  class CommandLineRunner < Optitron::CLI
    
    desc "Starts a quebert worker"
    opt "pid-file",     :type => :string
    opt "log-file",     :type => :string
    opt "config-file",  :type => :string
    opt "chdir",        :type => :string
    def worker
      if dir = params['chdir']
        Dir.chdir dir
      end
      
      if pid_file = params['pid-file']
        Support::PidFile.new(pid_file).write!
      end
      
      if log_path = params['log-file']
        Quebert.config.log_file_path = log_path
      end
      
      if config = params['config-file'] || auto_config
        require config
      end
      
      Worker.new.start
    end
    
  private
    def auto_config
      rails_env_path = './config/environment.rb'
      if File.exists?(rails_env_path)
        Quebert.logger.info "Detected Rails! Setting config-file=#{File.expand_path(rails_env_path)}"
        rails_env_path
      end
    end
  end
end