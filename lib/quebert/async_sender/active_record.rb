module Quebert
  module AsyncSender
    # I'm not sure if I want to do this or build serializers per type of object...
    module ActiveRecord
      # Reference an AR with the pk
      class PersistedRecordJob < Job
        def perform(model_name, pk, meth, args)
          Support.constantize(model_name).find(pk).send(meth, *args)
        end
      end
      
      # Serialize an unpersisted AR with the attributes on the thing.
      class UnpersistedRecordJob < Job
        def perform(model_name, attrs, meth, args)
          self.class.deserialize(Support.constantize(model_name).new, attrs).send(meth, *args)
        end
        
        # Deal with converting an AR to/from a hash that we can send over the wire.
        def self.serialize(record)
          record.attributes.inject({}) do |hash, (attr, val)|
            hash[attr] = val
            hash
          end
        end
        
        def self.deserialize(record, attrs)
          record.attributes.each do |attr, val|
            record.send("#{attr}=", attrs[attr])
          end
          record
        end
      end
      
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.send(:extend, ClassMethods)
      end
      
      module InstanceMethods
        # The meat of dealing with ActiveRecord instances.
        def async_send(meth, *args)
          if self.new_record?
            UnpersistedRecordJob.enqueue(self.class.model_name, UnpersistedRecordJob.serialize(self), meth, args)
          else
            PersistedRecordJob.enqueue(self.class.model_name, id, meth, args)
          end
        end
      end
      
      # Get the model name of the Model. Can't just do class.name on this...
      module ClassMethods
        def async_send(meth, *args)
          Object::ObjectJob.enqueue(self.model_name, meth, args)
        end
      end
    end
  end
end