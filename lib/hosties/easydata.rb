###############################################################
# Provide a more convenient data structure to work with once  #
# environment declarations have been read.                    #
###############################################################
module Hosties
  module EasyData
    class DataWrapper
      def metaclass
        class << self
          self
        end
      end
    end
    def self.fromHost(hash)
      result = DataWrapper.new
      hash.each do |k, v|
        result.metaclass.send(:define_method, k) do v end
      end
      result
    end
    def self.fromEnv(hash)
      result = DataWrapper.new
      hash.each do |k, v|
        result.metaclass.send(:define_method, k) do v end
      end
      # Add a hosts_by_type method
      result.metaclass.send(:define_method, :hosts_by_type) do |type|
        self.hosts.find_all do |host|
          host.type == type
        end
      end
      # Add an each_host method
      result.metaclass.send(:define_method, :each_host) do |&block|
        yield self.hosts
      end
      # Apply all of the host_attributes to our little host children
      definition = Hosties::EnvironmentDefinitions[hash[:type]]
      inheritance = definition.host_attributes
      hash[:hosts].each do |host|
        inheritance.each do |attr|
          val = hash[attr]
          host.metaclass.send(:define_method, attr) do val end
        end
      end
      result
    end
  end
end
