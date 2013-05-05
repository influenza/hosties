require 'spec_helper'

describe Hosties do
  it 'defines host types' do
    # Declare a host type
    host_type :logger do
      have_services :jmx, :rest, :http, :https
      have_attributes :control_mbean, :default_user
    end
  end

  it 'defines environments comprised of host types' do
    host_type :mutant_maker do
      have_services :laser_blaster, :chainsaw_arms, :coffee_bar
      have_attributes :height, :weight, :brutality
    end
    host_type :turkey_blaster do
      have_service :turkey_blast
      have_attribute :blast_force
    end
    environment_type :weird_thanksgiving do
      need :mutant_maker, :turkey_blaster
      have_attribute :weirdness_factor
    end
  end

  it 'rejects host definitions with constraints on nonexistent attributes' do
    host_type :fake_attributes do
      have_attributes :foo, :bar
      where(:baz).can_be "Anything!", "It doesn't", "exist anyway."
    end
    expect(Hosties::HostDefinitions.include? :fake_attributes).to eq(false)
  end

  it 'rejects environment definitions that need undefined host types' do
    environment_type :failure do
      need :nonexistent
    end
    expect(Hosties::EnvironmentDefinitions.include? :failure).to eq(false)
  end

  it 'can enforce attribute constraints' do
    definition = HasAttributes.new
    definition.have_attributes(:x, :y, :z)
    definition.where(:x).can_be("hello", "turkey", 42)
    instance = UsesAttributes.new(definition)
    instance.y = "Why?!"
    expect(instance.y).to eq("Why?!")
    expect { instance.x = 31 }.to raise_error(ArgumentError)
    instance.x = "turkey"
    expect(instance.x).to eq("turkey")
  end

  it 'can declare a host' do
    host_type :special_host do
    end
    instance = HostBuilder.new(:special_host, "0.0.0.0")
    expect(instance.finish).to eq({ :hostname => "0.0.0.0"})
  end

  it 'catches missing services' do
    host_type :web_host do
      have_service :http
    end
    instance = HostBuilder.new(:web_host, "0.0.0.0")
    expect { instance.finish }.to raise_error(ArgumentError)
  end

  it 'catches missing attributes' do
    host_type :mud_server do
      have_attribute :version
    end
    instance = HostBuilder.new(:mud_server, "0.0.0.0")
    expect { instance.finish }.to raise_error(ArgumentError)
  end

  it 'catches non-integral service ports' do
    host_type :web_host do
      have_service :http
    end
    instance = HostBuilder.new(:web_host, "0.0.0.0")
    instance.http = 10.4
    expect { instance.finish }.to raise_error(ArgumentError)
  end
end
