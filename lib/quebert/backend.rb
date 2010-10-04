module Quebert
  module Backend
    autoload :InProcess,  'quebert/backend/in_process.rb'
    autoload :Beanstalk,  'quebert/backend/beanstalk.rb'
    autoload :Sync,       'quebert/backend/sync.rb'
  end
end