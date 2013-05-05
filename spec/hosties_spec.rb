require 'spec_helper'

describe Hosties do
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
    builder = EnvironmentBuilder.new(:needy_environment)
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
    expect(Hosties::RegisteredEnvironments[:typical_product].nil?).to eq(false)
    data = Hosties::RegisteredEnvironments[:typical_product].first
    expect(data[:environment]).to eq(:qa)
    expect(data[:hosts][:monitoring].size).to eq(2) # Two monitoring hosts
    expect(data[:hosts][:service_host].size).to eq(1)
    service_host = data[:hosts][:service_host].first
    expect(service_host[:service_port]).to eq(1234)
    expect(service_host[:uuid]).to eq("81E3C1D4-C040-4D59-A56F-4273384D576B")
  end
end
