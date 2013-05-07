require 'spec_helper'

describe Hosties do
  it 'can declare a host' do
    host_type :special_host do
    end
    instance = Hosties::HostBuilder.new(:special_host, "0.0.0.0")
    expect(instance.finish).to eq({ :hostname => "0.0.0.0", :type => :special_host})
  end

  it 'catches missing services' do
    host_type :web_host do
      have_service :http
    end
    instance = Hosties::HostBuilder.new(:web_host, "0.0.0.0")
    expect { instance.finish }.to raise_error(ArgumentError)
  end

  it 'catches missing attributes' do
    host_type :mud_server do
      have_attribute :version
    end
    instance = Hosties::HostBuilder.new(:mud_server, "0.0.0.0")
    expect { instance.finish }.to raise_error(ArgumentError)
  end

  it 'catches non-integral service ports' do
    host_type :web_host do
      have_service :http
    end
    instance = Hosties::HostBuilder.new(:web_host, "0.0.0.0")
    expect { instance.http 10.4 }.to raise_error(ArgumentError)
  end

  it 'catches missing host requirements' do
    host_type :type_a do
    end
    host_type :type_b do
    end
    environment_type :needy_environment do
      need :type_a, :type_b
    end
    builder = Hosties::EnvironmentBuilder.new(:needy_environment)
    builder.type_a "0.0.0.0" do end
    # No type_b specified
    expect { builder.finish }.to raise_error(ArgumentError)
  end

  it 'can fully declare an environment' do
    # Declare the host types
    host_type :monitoring do
      have_services :logging, :http
    end
    host_type :service_host do
      have_services :service_port, :rest, :jmx
      have_attribute :uuid
    end
    # Declare this product's environment makeup
    environment_type :typical_product do
      need :service_host, :monitoring
      have_attribute :environment
      where(:environment).can_be(:dev, :qa, :live)
    end
    # make one!
    environment_for :typical_product do
      environment :qa
      monitoring "192.168.0.1" do
        logging 8888
        http 80
      end
      monitoring "192.168.0.2" do
        logging 8888
        http 80
      end
      service_host "192.168.0.3" do
        service_port 1234
        rest 8080
        jmx 9876
        uuid "81E3C1D4-C040-4D59-A56F-4273384D576B"
      end
    end
    expect(Hosties::Environments[:typical_product].nil?).to eq(false)
    data = Hosties::Environments[:typical_product].first
    expect(data.environment).to eq(:qa)
    expect(data.hosts_by_type(:monitoring).size).to eq(2) # Two monitoring hosts
    expect(data.hosts_by_type(:service_host).size).to eq(1)
    service_host = data.hosts_by_type(:service_host).first
    expect(service_host.service_port).to eq(1234)
    expect(service_host.uuid).to eq("81E3C1D4-C040-4D59-A56F-4273384D576B")
  end

  it 'can group environments by attribute' do
    host_type :foo do end
    host_type :bar do end
    environment_type :foobar do
      need :foo, :bar
      have_attribute :env_type
      where(:env_type).can_be :dev, :qa, :live
      grouped_by :env_type
    end
    environment_for :foobar do
      foo "0.0.0.0" do end
      bar "0.0.0.0" do end
      env_type :dev
    end
    environment_for :foobar do
      foo "0.0.0.0" do end
      bar "0.0.0.0" do end
      env_type :qa
    end
    expect(Hosties::GroupedEnvironments[:foobar][:dev].size).to eq(1)
    expect(Hosties::GroupedEnvironments[:foobar][:qa].size).to eq(1)
  end

  it 'lets hosts inherit attributes' do
    host_type :beneficiary do end# ha.
    environment_type :benefactor do
      need :beneficiary
      has_attribute :monies
      hosts_inherit :monies # Lucky!
    end
    amount = 1000000
    environment_for :benefactor do
      beneficiary "0.0.0.0" do end
      # Prove that ordering doesn't matter here
      monies amount
    end
    beneficiary = Hosties::Environments[:benefactor].first.hosts.first
    expect(beneficiary.monies).to eq(amount)
  end
end
