# frozen_string_literal: true

require 'rspec'
require_relative '../lib/version'

describe Version do
  let(:subject) { described_class.new('1.2.3') }

  it 'returns the major version' do
    expect(subject.major).to eq(1)
  end

  it 'returns the minor version' do
    expect(subject.minor).to eq(2)
  end

  it 'returns the patch version' do
    expect(subject.patch).to eq(3)
  end

  describe '#compare_to' do
    shared_examples "the other version is larger" do |other|
      it 'returns the larger version' do
        expect(subject.compare_to(other)).to eq(other)
      end
    end

    shared_examples "the subject version is larger" do |other|
      it 'returns the larger version' do
        expect(subject.compare_to(other)).to eq(subject)
      end
    end

    include_examples "the other version is larger", Version.new('2.0.0')
    include_examples "the other version is larger", Version.new('1.3.0')
    include_examples "the other version is larger", Version.new('1.2.4')

    include_examples "the subject version is larger", Version.new('1.2.2')
    include_examples "the subject version is larger", Version.new('1.1.4')
    include_examples "the subject version is larger", Version.new('0.5.6')
  end
end
