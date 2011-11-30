# Setup a namespaced Quebert::Timeout class that will deal with responsible folks in
# 1.8.7 who use the SystemTimer gem.
module Quebert
  Timeout = begin
    require 'system_timer'
    ::SystemTimer
  rescue LoadError
    # Install the system_timer gem if you're running this in Ruby 1.8.7!
    require 'timeout'
    ::Timeout
  end
end