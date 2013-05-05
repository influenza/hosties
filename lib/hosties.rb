require 'hosties/definitions'

# A library to provide easily readable environment definitions.
module Hosties
  # Environment definitions, keyed by type
  EnvironmentDefinitions = {}
  # Host definitions, keyed by type
  HostDefinitions = {}
  # Environment instances, keyed by name
  RegisteredEnvironments = {}
end
