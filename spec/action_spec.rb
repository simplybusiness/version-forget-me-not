require 'rspec'
require_relative '../lib/action'

describe Action do
  it 'returns the correct version for master branch' do
    expect(Action.new.get_version(ref: 'master')).to eq('1.0.0')
  end
end
