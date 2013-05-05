# Fancy words, fancy words.
# Provide some classes to turn a declarative host definition into something 
# more useful in code, applying rules from the definition files to ensure we
# only get valid stuff.
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
    # TODO: More clever data repackaging
    super.merge({ :hostname => @hostname }).merge(@service_ports)
  end
end

# Turn a description into a useful data structure - and it's validated!
class EnvironmentBuilder < UsesAttributes
  def initialize(type)
    if Hosties::EnvironmentDefinitions[type].nil? then
      raise ArgumentError, "Unrecognized environment type"
    end
    @hosts = {} # host type => array of hosts' data
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
          if @hosts[host_type].nil? then @hosts[host_type] = [] end
          @hosts[host_type] << builder.finish
        rescue ArgumentError => ex
          puts "Problem declaring host: #{ex}"
          raise ex
        end
      end
    end
  end
  def finish
    # Verify all of the required hosts were set
    @definition.hosts.each do |host_type| 
      raise ArgumentError, "Missing #{host_type} host" unless @hosts.include? host_type
    end
    retval = super.merge({ :hosts => @hosts })
    if Hosties::RegisteredEnvironments[@type].nil? then
      Hosties::RegisteredEnvironments[@type] = []
    end
    Hosties::RegisteredEnvironments[@type] << retval
    retval
  end
end

def environment_for(type, &block)
  # Verify this is a legit type of environment
  begin
    builder = EnvironmentBuilder.new(type)
    builder.instance_eval(&block)
    data = builder.finish
  rescue ArgumentError => ex
    puts "Problem declaring environment: #{ex}"
    raise ex
  end
end
