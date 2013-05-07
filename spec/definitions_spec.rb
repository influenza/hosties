require 'spec_helper'

describe Hosties::HasAttributes do
  it 'rejects definitions with constraints on nonexistent attributes' do
    instance = Hosties::HasAttributes.new
    instance.have_attributes :foo, :bar
    expect { instance.where(:baz).can_be("anything") }.to raise_error(ArgumentError)
  end
end

describe Hosties::HostRequirement do
  it 'defines host types' do
    # Declare a host type
    host_type :logger do
      have_services :jmx, :rest, :http, :https
      have_attributes :control_mbean, :default_user
    end
  end
end

describe Hosties::EnvironmentRequirement do
  it 'defines environments with host and attribute requirements' do
    host_type :mutant_maker do end
    host_type :turkey_blaster do end
    environment_type :weird_thanksgiving do
      need :mutant_maker, :turkey_blaster
      have_attribute :weirdness_factor
    end
  end

  it 'rejects environment definitions that need undefined host types' do
    builder = Hosties::EnvironmentRequirement.new(:failure)
    expect { builder.need(:nonexistent) }.to raise_error(ArgumentError)
  end

  it 'rejects groupings for unknown attributes' do
    builder = Hosties::EnvironmentRequirement.new(:failure)
    expect { builder.grouped_by(:nonexistent) }.to raise_error(ArgumentError)
  end
end
