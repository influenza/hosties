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

  it 'can constrain attributes' do
    host_type :that_novel do
      have_attributes :length, :awesomeness
      where(:length).can_be :short, :medium, :long, :omg_srsly
      where(:awesomeness).can_be :terribad, :s_ok, :great
    end
  end
end
