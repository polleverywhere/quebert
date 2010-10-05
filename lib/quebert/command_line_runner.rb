module Quebert
  class CommandLineRunner
    
    attr_accessor :arguments, :command, :options
    
    def initialize(argv)
      @argv = argv
      
      # Default options values
      @options = {
        :chdir  => Dir.pwd
      }
      
      parse!
    end
    
    def parser
      @parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: quebert [options]"
        
        opts.separator ""
        
        opts.on("-l", "--log FILE", "File to redirect output " +                      
                                    "(default: #{@options[:log]})")                   { |file| @options[:log] = file }
        opts.on("-P", "--pid FILE", "File to store PID " +                            
                                    "(default: #{@options[:pid]})")                   { |file| @options[:pid] = file }
        opts.on("-C", "--config FILE", "Load options from config file")               { |file| @options[:config] = file }
        opts.on("-c", "--chdir DIR", "Change to dir before starting")                 { |dir| @options[:chdir] = File.expand_path(dir) }
      end
    end
    
    # Parse the options.
    def parse!
      parser.parse! @argv
      @command   = @argv.shift
      @arguments = @argv
    end
    
    def self.dispatch(args = ARGV)
      runner = new(args)
      params = runner.options
      
      if dir = params[:chdir]
        Dir.chdir dir
      end

      if pid_file = params[:pid]
        Support::PidFile.new(pid_file).write!
      end

      if log_path = params[:log]
        Quebert.config.log_file_path = log_path
      end

      if config = params[:config] || auto_config
        require config
      end
      
      Worker.new.start
    end
    
  private
    def self.auto_config
      rails_env_path = './config/environment.rb'
      if File.exists?(rails_env_path)
        Quebert.logger.info "Detected Rails! Setting config-file=#{rails_env_path}"
        rails_env_path
      end
    end
  end
end