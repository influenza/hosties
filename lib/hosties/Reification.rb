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
    # Magic.
    has_attributes.attributes.each do |attr|
      # Add in the attribute
      self.metaclass.send(:attr_accessor, attr)
      # Define a constrained setter
      self.metaclass.send(:define_method, "#{attr}=") do |val|
        raise ArgumentError, "Invalid value" unless has_attributes.valid?(attr, val)
        instance_variable_set "@#{attr}", val
      end
      # Define a liberal accessor
      self.metaclass.send(:define_method, attr) do instance_variable_get "@#{attr}" end
    end
  end
end

class HostBuilder < UsesAttributes
  def initialize(type, hostname)
    if Hosties::HostDefinitions[@type].nil? then
      raise ArgumentError, "Unrecognized host type"
    end
    @type = type
    @definition = Hosties::HostDefinitions[@type]
    @hostname = hostname
    super(@definition) # Creates attribute code
  end
  def finish
    # TODO: More clever data repackaging
    { :hostname => @hostname }
  end
end

# Turn a description into a useful data structure - and it's validated!
class EnvironmentBuilder < UsesAttributes
  def initialize(type)
    if Hosties::EnvironmentDefinitions[@type].nil? then
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
          @hosts << builder.finish
        rescue ArgumentError => ex
          # Let the user know somehow
        end
      end
    end
  end
  def finish
    if Hosties::RegisteredEnvironments[@type].nil? then
      Hosties::RegisteredEnvironments[@type] = []
    end
    # TODO: Actually do some repackaging of the data here
    Hosties::RegisteredEnvironments[@name] << self
  end
end

def environment_for(type, &block)
  # Verify this is a legit type of environment
  begin
    builder = EnvironmentBuilder.new(type)
    builder.instance_eval(&block)
    builder.finish
  rescue ArgumentError => ex
  end
end
