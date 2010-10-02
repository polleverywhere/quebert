require 'logger'

module Quebert
  class Worker
    attr_accessor :exception_handler, :log_file, :backend
    
    include Quebert::Worker::Daemonizable
    
    def initialize
      yield self if block_given?
    end
    
    # Start the worker backend and intercept exceptions if a handler is provided
    def start
      while job = backend.reserve do
        begin
          job.perform
        rescue Exception => e
          exception_handler ? exception_handler.call(e) : raise(e)
        end
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
    def log(message)
      puts message
    end
  end
end