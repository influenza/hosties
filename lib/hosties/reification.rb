# Fancy words, fancy words.
# Provide some classes to turn a declarative host definition into something 
# more useful in code, applying rules from the definition files to ensure we
# only get valid stuff.

module Hosties
  class UsesAttributes
    # Oh this old thing...
    def metaclass 
      class << self
        self
      end
    end
    def initialize(has_attributes)
      @attributes = has_attributes.attributes
      # Magic.
      has_attributes.attributes.each do |attr|
        # Add in the attribute
        self.metaclass.send(:attr_accessor, attr)
        # Define a constrained setter
        self.metaclass.send(:define_method, attr) do |val|
          raise ArgumentError, "Invalid value" unless has_attributes.valid?(attr, val)
          instance_variable_set "@#{attr}", val
        end
      end
    end

    # Return a hash after verifying everything was set correctly
    def finish
      retval = {}
      # Ensure all required attributes have been set
      @attributes.each do |attr|
        val = instance_variable_get "@#{attr}"
        raise ArgumentError, "Missing attribute #{attr}" if val.nil?
        retval[attr] = val
      end
      retval
    end
  end

  class HostBuilder < UsesAttributes
    def initialize(type, hostname)
      if Hosties::HostDefinitions[type].nil? then
        raise ArgumentError, "Unrecognized host type"
      end
      @type = type
      @definition = Hosties::HostDefinitions[@type]
      @hostname = hostname
      @service_ports = {} # Map of service type to port
      super(@definition) # Creates attribute code
      # Services are really just a special kind of attribute, but for now I'll
      # keep them separate. I'm thinking maybe I could add a new type of attribute
      # constraint that let's a user specify that an attribute must be numeric, or
      # a string for instance.
      @definition.services.each do |service_type|
        self.metaclass.send(:attr_accessor, service_type)
        self.metaclass.send(:define_method, service_type) do |port|
          raise ArgumentError, "Port number required" unless port.is_a? Integer
          @service_ports[service_type] = port
        end
      end
    end

    def finish
      # Ensure all services have been set
      @definition.services.each do |svc|
        raise ArgumentError, "Missing service #{svc}" if @service_ports[svc].nil?
      end
      # TODO: Declare these reserved names
      super.merge({ :hostname => @hostname, :type => @type }).merge(@service_ports)
    end
  end

  # Turn a description into a useful data structure - and it's validated!
  class EnvironmentBuilder < UsesAttributes
    def initialize(type)
      if Hosties::EnvironmentDefinitions[type].nil? then
        raise ArgumentError, "Unrecognized environment type"
      end
      @hosts = [] 
      @type = type
      @definition = Hosties::EnvironmentDefinitions[@type]
      super(@definition) # Creates attribute code
      # More magic, this time create a parameterized host builder based 
      # on the type of hosts this environment wants. Poor man's currying
      @definition.hosts.each do |host_type|
        self.metaclass.send(:define_method, host_type) do |hostname, &block|
          begin
            builder = HostBuilder.new(host_type, hostname)
            builder.instance_eval(&block)
            @hosts << Hosties::EasyData.fromHost(builder.finish)
          rescue ArgumentError => ex
            #puts "Problem declaring host: #{ex}"
            raise ex
          end
        end
      end
    end

    def finish
      # Verify all of the required hosts were set
      @definition.hosts.each do |host_type| 
        unless @hosts.detect { |host| host.type == host_type } then
          raise ArgumentError, "Missing #{host_type} host" 
        end
      end
      super.merge({ :type => @type, :hosts => @hosts })
    end
  end
end

## Globally accessible builder methods
def environment_for(type, &block)
  begin
    builder = Hosties::EnvironmentBuilder.new(type)
    builder.instance_eval(&block)
    data = builder.finish
    nice_version = Hosties::EasyData.fromEnv(data)
    Hosties::Environments[type] << nice_version
    definition = Hosties::EnvironmentDefinitions[type]
    # Add into the grouped listing if necessary
    unless definition.grouping.nil? then 
      if Hosties::GroupedEnvironments[type].nil? then
        Hosties::GroupedEnvironments[type] = Hash.new{|h,k| h[k] = []}
      end
      Hosties::GroupedEnvironments[type][data[definition.grouping]] << nice_version
    end
  rescue ArgumentError => ex
    puts "Problem declaring environment: #{ex}"
    raise ex
  end
end
