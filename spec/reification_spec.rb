require 'spec_helper'

describe Hosties::UsesAttributes do
  it 'can enforce attribute constraints' do
    definition = Hosties::HasAttributes.new
    definition.have_attributes(:x)
    definition.where(:x).can_be("hello")
    instance = Hosties::UsesAttributes.new(definition)
    instance.x "hello"
    expect { instance.x 31 }.to raise_error(ArgumentError)
  end
  it 'catches missing attributes' do
    definition = Hosties::HasAttributes.new
    definition.have_attributes(:x)
    instance = Hosties::UsesAttributes.new(definition)
    expect { instance.finish }.to raise_error(ArgumentError)
  end
end
