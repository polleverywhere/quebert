# require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
# 
# describe "Quebert" do
#   before(:all) do
# 
#     class CalcyCalc
#       include Quebert::AsyncSend
#       
#       def add(*numbers)
#         numbers.inject(0){|num, sum| sum = sum + num }
#       end
#     end
#     
#     CalcyCalc.async_sender.queue = @q = Backend::InProcess.new
#     @calc = CalcyCalc.new
#   end
#   
#   it "should drop a job in a producer" do
#     lambda{
#       @calc.async_send :add, 1, 2, 3
#     }.should change(CalcyCalc.async_sender.producer.queue, :size).by(1)
#   end
#   
#   it "should instanciate AsyncConsumer from worker" do
#     lambda{
#       worker = Quebert::Worker.new do |w|
#         w.queue = @queue
#       end
#       worker.job.should be_instance_of(Quebert::AsyncSend::InstanceJob)
#     }.should change(@queue, :size).by(-1)
#   end
# end