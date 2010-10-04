module Quebert
  module Support
    
    # Deal with all of our pid file stuff
    class PidFile
      
      attr_reader :path
      
      ProcessRunning = Class.new(RuntimeError)
      
      def initialize(path)
        @path = path
      end
      
      def write!
        remove_stale and write
      end
      
      # Read pids and turn them into ints
      def self.read(file)
        if File.file?(file) && pid = File.read(file)
          pid.to_i
        else
          nil
        end
      end
      
      # Tells us if a current process is running
      def self.running?(pid)
        Process.getpgid(pid) != -1
      rescue Errno::EPERM
        true
      rescue Errno::ESRCH
        false
      end
      
    private
      # If PID file is stale, remove it.
      def remove_stale
        if exists? && running?
          raise ProcessRunning, "#{path} already exists, seems like it's already running (process ID: #{pid}). " +
                              "Stop the process or delete #{path}."
        else
          remove
        end
      end
      
      def remove
        File.delete(path) if exists?
        true
      end
      
      def write
        File.open(path,"w") { |f| f.write(Process.pid) }
        File.chmod(0644, path)
      end
      
      def pid
        self.class.read(path)
      end
      
      def running?
        self.class.running?(pid)
      end
      
      def exists?
        File.exist?(path)
      end
    end
    
  end
end