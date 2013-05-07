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
      # Define a human-friendly to_s
      # NOTE: Application behavior should not rely on the stability of this
      # string representation! It is subject to change whenever I'm feeling
      # squirrely.
      filtered_hash = hash.reject { |k,v| k == :type or k == :hostname }
      attr_string = filtered_hash.map{|k,v| "#{k}: #{v}"}.join(", ")
      result.metaclass.send(:define_method, :to_s) do
        "<#{hash[:type]} host @ #{hash[:hostname]} attrs: #{attr_string}>"
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
      # Human friendly to_s
      # NOTE: As above, this representation is subject to change whenever,
      # don't rely on it for application behavior!
      filtered_hash = hash.reject { |k,v| k == :type or k == :hosts }
      attr_string = filtered_hash.map{|k,v| "#{k}: #{v}"}.join(", ")
      result.metaclass.send(:define_method, :to_s) do
        "<#{hash[:type]} environment, attrs: #{attr_string}, hosts: #{hash[:hosts].join(", ")}>"
      end
      result
    end
  end
end
