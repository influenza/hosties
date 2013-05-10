#######################################################################
# Provide some classes to give us friendly, easy on the eyes syntax   #
# for defining what different types of hosts and environments should  #
# have in order to be valid.                                          #
#######################################################################

module Hosties
  # Constrains a named attribute to a provided set of values. This is good
  # for things like describing environments that a set of hosts can be in,
  # for instance Dev, QA, etc
  class AttributeConstraint
    attr_reader :name, :possible_vals

    def initialize(name)
      @name = name
      @possible_vals = []
    end

    def can_be(val, *more)
      @possible_vals += (more << val)
    end
  end

  # Superclass for the host and environment requirement types. This 
  # class handles the plumbing of tracking, constraining, and eventually
  # reifying attributes.
  class HasAttributes
    attr_accessor :constraints
    attr_accessor :attributes

    def initialize(verbotten = [])
      @constraints = {}
      @attributes = []
      @verbotten = verbotten
    end

    # Specify symbols that will later be reified into attributes
    def have_attributes(attr, *more)
      sum = (more << attr)
      sum.each do |name|
        raise ArgumentError, "Reserved attribute name #{name}" if @verbotten.include?(name)
      end
      @attributes += sum
    end

    alias_method :have_attribute, :have_attributes
    alias_method :has_attribute, :have_attribute
    alias_method :has_attributes, :have_attributes

    # Helpful method to define constraints
    def where(name)
      # Must define the attributes before constraining them
      raise ArgumentError, "Unknown attribute: #{name}" unless @attributes.include? name
      @constraints[name] = AttributeConstraint.new(name)
    end

    # Check if a given name-value pair is valid given the constraints
    def valid?(name, value)
      if @constraints.include? name then
        constraints[name].possible_vals.include? value
      else true end
    end
  end

  # Defines what a host of a certain type looks like
  class HostRequirement < HasAttributes
    attr_reader :type, :services
    def initialize(type)
      super([:hostname, :type])
      @type = type
      @services = []
    end

    # Services will be provided with a host definition. In order for
    # a host definition to be valid, it must provide service details 
    # for all of the services specified by its matching 
    # HostRequirement
    def have_services(service, *more)
     @services += (more << service)
    end

    alias_method :have_service, :have_services
    alias_method :has_service, :have_service
    alias_method :has_services, :have_services

    def finished
      Hosties::HostDefinitions[@type] = self
    end
  end


  # Used to describe an environment.
  class EnvironmentRequirement < HasAttributes
    attr_reader :type, :hosts, :grouping, :host_attributes
    def initialize(type)
      super([:type, :hosts])
      @type = type
      @host_attributes = []
      @hosts = []
    end

    # Define the hosts that an environment needs to be valid,
    # for instance, maybe you need a :logger host and a 
    # :service host at a minimum.
    def need(host1, *more)
      sum = more << host1
      # Array doesn't have an 'exists' method, so behold - map reduce wankery!
      unless sum.map { |x| Hosties::HostDefinitions.include? x }.reduce(true) { |xs, x| x & xs }
        raise ArgumentError, "Unrecognized host type"
      end
      @hosts += sum
    end

    alias_method :needs, :need

    def hosts_inherit(attr)
      unless self.attributes.include? attr then
        raise ArgumentError, "Unrecognized attribute #{attr}"
      end
      @host_attributes << attr
    end

    # Optionally specify an attribute to group by when registering 
    # environments of this type.
    def grouped_by(attr) 
      raise ArgumentError, "Unknown attribute #{attr}" unless @attributes.include?(attr)
      @grouping = attr
    end

    def finished
      Hosties::EnvironmentDefinitions[@type] = self
    end
  end
end

## Globally accessible builder methods

def environment_type(symbol, &block)
  builder = Hosties::EnvironmentRequirement.new(symbol)
  builder.instance_eval(&block)
  builder.finished
end

def host_type(symbol, &block)
  builder = Hosties::HostRequirement.new(symbol)
  builder.instance_eval(&block)
  builder.finished
end
