#######################################################################
# Provide some classes to give us friendly, easy on the eyes syntax   #
# for defining what different types of hosts and environments should  #
# have in order to be valid.                                          #
#######################################################################

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
  def initialize
    @constraints = {}
    @attributes = []
  end

  # Specify symbols that will later be reified into attributes
  def have_attributes(attr, *more)
   @attributes += (more << attr)
  end

  alias_method :have_attribute, :have_attributes

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
    super()
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

  def finished
    Hosties::HostDefinitions[@type] = self
  end
end

# Builder method
def host_type(symbol, &block)
  builder = HostRequirement.new(symbol)
  begin
    builder.instance_eval(&block)
    builder.finished
  rescue ArgumentError => ex
    # TODO: There must be a better way!
    # I'd like to provide some feedback in this case, but I don't 
    # like having this show up in test output. 
    #puts "Problem defining host \"#{symbol}\": #{ex}"
  end
end

# Used to describe an environment.
class EnvironmentRequirement < HasAttributes
  attr_reader :type, :hosts, :grouping
  def initialize(type)
    super()
    @type = type
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

# Builder method
def environment_type(symbol, &block)
  builder = EnvironmentRequirement.new(symbol)
  begin
    builder.instance_eval(&block)
    builder.finished
  rescue ArgumentError => ex
    # TODO: Same as above, find a better way to get this information out
    #puts "Problem describing environment \"#{builder.type}\": #{ex}"
  end
end
