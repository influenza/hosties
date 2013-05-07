require 'spec_helper'

describe Hosties::EasyData do
  it 'should turn host declarations into something awesome' do
    host_type :easydata_one do
      have_service :http
      have_attribute :attr_one
    end
    builder = Hosties::HostBuilder.new(:easydata_one, "localhost")
    builder.http 80
    builder.attr_one "One!"
    result = Hosties::EasyData.fromHost(builder.finish)
    expect(result.http).to eq(80)
    expect(result.attr_one).to eq("One!")
    expect(result.hostname).to eq("localhost")
    expect(result.type).to eq(:easydata_one)
  end

  it 'should turn environment declarations into something awesome too' do
    host_type :easydata_two do end
    host_type :easydata_three do end
    environment_type :easydata_one do
      need :easydata_two, :easydata_three
      have_attribute :environment
      where(:environment).can_be :dev, :testing
    end
    builder = Hosties::EnvironmentBuilder.new :easydata_one
    builder.easydata_two "0.0.0.0" do end
    builder.easydata_three "1.1.1.1" do end
    builder.environment :dev
    result = Hosties::EasyData.fromEnv(builder.finish)
    expect(result.environment).to eq(:dev)
    type_two_hosts = result.hosts_by_type(:easydata_two)
    expect(type_two_hosts.size).to eq(1)
    host = type_two_hosts.first
    expect(host.hostname).to eq("0.0.0.0")
  end
end
