require 'active_record'

ActiveRecord::Base.establish_connection({
  :adapter => 'sqlite3',
  :database => ':memory:'
})

ActiveRecord::Schema.define do
  create_table "users", :force => true do |t|
    t.column "first_name",  :text
    t.column "last_name",  :text
    t.column "email", :text
  end
end

class User < ActiveRecord::Base
  include Quebert::AsyncSender::ActiveRecord
  
  def name
    "#{first_name} #{last_name}"
  end
  
  def self.emailizer(address)
    address
  end

  def email(address)
    address
  end
end