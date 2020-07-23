require 'rspec'
require_relative '../lib/action'

describe Action do
  it 'get the version' do
    expect(Action.new.get_version(ref: 'master')).to eq('1.0.0')
  end
end
