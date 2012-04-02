require 'rubygems'
require 'bundler/setup'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'quebert'
require 'logger'

include Quebert
Quebert.config.logger = Logger.new('/dev/null') # Shhh...

def clean_file(path, contents=nil, &block)
  FileUtils.remove_entry(path) if File.exists?(path)
  FileUtils.mkdir_p(File.dirname(path))
  begin
    File.open(path, 'w'){|f| f.write(contents == :empty ? nil : contents) } unless contents.nil?
    block.call
  ensure
    FileUtils.remove_entry(path) if File.exists?(path) and path != './'  # Yeah! This has happened before :(
  end
end

Dir[File.join(File.dirname(__FILE__), 'support/*.rb')].each {|file| require file }

Quebert.serializers.register 'ActiveRecord::Base', Serializer::ActiveRecord