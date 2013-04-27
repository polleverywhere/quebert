module Quebert
  module AsyncSender
    # Perform jobs on instances of classes
    module Instance
      class InstanceJob < Job
        def perform(klass, initialize_args, meth, *args)
          Support.constantize(klass).new(*initialize_args).send(meth, *args)
        end
      end

      def self.included(base)
        # Its not as simple as including initialize in a class, we
        # have to do some tricks to make it work so we can put the include
        # before the initialize method as opposed to after. Ah, and thanks PivotalLabs for this.
        base.send(:include, AsyncSender::Promise::DSL)
        base.send(:include, InstanceMethods)
        base.send(:extend,  ClassMethods)
        base.overwrite_initialize
        base.instance_eval do
          def method_added(name)
            return if name != :initialize
            overwrite_initialize
          end
        end
      end

      module InstanceMethods
        # Build a job that uses the @__initialize_args
        def build_job(meth, *args)
          InstanceJob.new(self.class.name, @__initialize_args, meth, *args)
        end

        # Remember the args used to initialize the class so that
        # we can serialize them into a Job.
        def initialize_with_async_sender(*args)
          initialize_without_async_sender(*(@__initialize_args = args))
        end
      end
      
      module ClassMethods
        # Hack into the class initialize method so that we can grab
        # the arguments used to create an instance of the class that
        # we can serialize into a job.
        def overwrite_initialize
          class_eval do
            unless method_defined?(:initialize_with_async_sender)
              define_method(:initialize_with_async_sender) do
                initialize_without_async_sender
              end
            end
            
            if instance_method(:initialize) != instance_method(:initialize_with_async_sender)
              alias_method :initialize_without_async_sender, :initialize
              alias_method :initialize, :initialize_with_async_sender
            end
          end
        end
      end
    end
  end
end