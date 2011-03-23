module Quebert
  module Serializer
    
    # Does this mean you could queue a job that could queue a job? Whoa!
    class Job
      def self.serialize(job)
        {
          'job' => job.class.name,
          'args' => serialize_args(job.args),
          'priority' => job.priority,
          'delay' => job.delay,
          'ttr' => job.ttr
        }
      end
      
      def self.deserialize(hash)
        hash = Support.stringify_keys(hash)
        job = Support.constantize(hash['job']).new(*deserialize_args(hash['args']))
        job.priority = hash['priority']
        job.delay = hash['delay']
        job.ttr = hash['ttr']
        job
      end
      
    private
    
      # Reflect on each arg and see if it has a seralizer
      def self.serialize_args(args)
        args.map do |arg|
          hash = Hash.new
          if serializer = Quebert.serializers[arg.class]
            hash['serializer'] = serializer.name
            hash['payload'] = serializer.serialize(arg)
          else
            hash['payload'] = arg
          end
          hash
        end
      end
      
      # Find a serializer and/or push out a value
      def self.deserialize_args(args)
        args.map do |arg|
          arg = Support.stringify_keys(arg)
          if arg.key? 'serializer' and serializer = Support.constantize(arg['serializer'])
            serializer.deserialize(arg['payload'])
          else
            arg['payload']
          end
        end
      end
    end
    
    # Deal with converting an AR to/from a hash that we can send over the wire.
    class ActiveRecord
      def self.serialize(record)
        attrs = record.attributes.inject({}) do |hash, (attr, val)|
          hash[attr] = val
          hash
        end
        { 'model' => record.class.model_name, 'attributes' => attrs }
      end
      
      def self.deserialize(hash)
        hash = Support.stringify_keys(hash)
        model = Support.constantize(hash.delete('model'))
        if attrs = Support.stringify_keys(hash.delete('attributes'))
          if id = attrs.delete('id')
            # This has been persisited, so just find it from the db
            model.find(id)
          else
            # Looks like its not around! Better generate it from attributes
            record = model.new
            record.attributes.each do |attr, val|
              record.send("#{attr}=", attrs[attr])
            end
            record
          end
        else
          model.new
        end
      end
    end
    
  end
end