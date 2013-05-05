require 'hosties/definitions'
require 'hosties/reification'

# A library to provide easily readable environment definitions.
module Hosties
  # Environment definitions, keyed by type
  EnvironmentDefinitions = {}
  # Host definitions, keyed by type
  HostDefinitions = {}
  # Environment instances, definition type => array of instances
  Environments = Hash.new{|h,k| h[k] = []}
  # Maps type => hash of specified 'grouped_by' value to array of matches
  GroupedEnvironments = {}
end
