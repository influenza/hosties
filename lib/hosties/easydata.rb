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
      result
    end
  end
end
