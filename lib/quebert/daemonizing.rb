require 'etc'
require 'daemons'
require 'fileutils'

module Process
  # Returns +true+ the process identied by +pid+ is running.
  def running?(pid)
    Process.getpgid(pid) != -1
  rescue Errno::EPERM
    true
  rescue Errno::ESRCH
    false
  end
  module_function :running?
end

module Quebert
  module Daemonizable
    attr_accessor :pid_file, :log_file
    
    PidFileExist = Class.new(RuntimeError)
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    def daemonize
      raise ArgumentError, 'You must specify a pid_file to daemonize' unless pid_file
      
      remove_stale_pid_file
      
      pwd = Dir.pwd # Current directory is changed during daemonization, so store it
      # HACK we need to create the directory before daemonization to prevent a bug under 1.9
      #      ignoring all signals when the directory is created after daemonization.
      FileUtils.mkdir_p File.dirname(pid_file)
      # Daemonize.daemonize(File.expand_path(@log_file), "quebert worker")
      Daemonize.daemonize(File.expand_path(@log_file), "quebert")
      Dir.chdir(pwd)
      write_pid_file
    end
    
    def pid
      File.exist?(pid_file) ? open(pid_file).read.to_i : nil
    end
    
    # Register a proc to be called to restart the server.
    def on_restart(&block)
      @on_restart = block
    end
    
    # Restart the server.
    def restart
      if @on_restart
        log '>> Restarting ...'
        stop
        remove_pid_file
        @on_restart.call
        exit!
      end
    end
    
    module ClassMethods
      # Send a QUIT or INT (if timeout is +0+) signal the process which
      # PID is stored in +pid_file+.
      # If the process is still running after +timeout+, KILL signal is
      # sent.
      def kill(pid_file, timeout=60)
        if timeout == 0
          send_signal('INT', pid_file, timeout)
        else
          send_signal('QUIT', pid_file, timeout)
        end
      end
      
      # Restart the server by sending HUP signal.
      def restart(pid_file)
        send_signal('HUP', pid_file)
      end
      
      # Send a +signal+ to the process which PID is stored in +pid_file+.
      def send_signal(signal, pid_file, timeout=60)
        if pid = read_pid_file(pid_file)
          Logging.log "Sending #{signal} signal to process #{pid} ... "
          Process.kill(signal, pid)
          Timeout.timeout(timeout) do
            sleep 0.1 while Process.running?(pid)
          end
        else
          Logging.log "Can't stop process, no PID found in #{pid_file}"
        end
      rescue Timeout::Error
        Logging.log "Timeout!"
        force_kill pid_file
      rescue Interrupt
        force_kill pid_file
      rescue Errno::ESRCH # No such process
        Logging.log "process not found!"
        force_kill pid_file
      end
      
      def force_kill(pid_file)
        if pid = read_pid_file(pid_file)
          Logging.log "Sending KILL signal to process #{pid} ... "
          Process.kill("KILL", pid)
          File.delete(pid_file) if File.exist?(pid_file)
        else
          Logging.log "Can't stop process, no PID found in #{pid_file}"
        end
      end
      
      def read_pid_file(file)
        if File.file?(file) && pid = File.read(file)
          pid.to_i
        else
          nil
        end
      end
    end
    
  protected
    def remove_pid_file
      File.delete(pid_file) if pid_file && File.exists?(pid_file)
    end
    
    def write_pid_file
      log ">> Writing PID to #{pid_file}"
      open(pid_file,"w") { |f| f.write(Process.pid) }
      File.chmod(0644, pid_file)
    end
    
    # If PID file is stale, remove it.
    def remove_stale_pid_file
      if File.exist?(pid_file)
        if pid && Process.running?(pid)
          raise PidFileExist, "#{pid_file} already exists, seems like it's already running (process ID: #{pid}). " +
                              "Stop the process or delete #{pid_file}."
        else
          log ">> Deleting stale PID file #{pid_file}"
          remove_pid_file
        end
      end
    end
  end
end