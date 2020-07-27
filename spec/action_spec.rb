# frozen_string_literal: true

require 'rspec'
require_relative '../lib/action'

describe Action do
  let(:client) { instance_double(Octokit::Client) }
  let(:action) { Action.new(owner: 'simplybusiness', repo: 'test', client: client) }

  describe '#version_changed?' do
    it 'return true if the github API response includes a version file' do
      allow(client).to receive(:pull_request_files).and_return(%w[version.rb foo.txt])
      expect(action.version_changed?(1)).to be_true
    end

    it 'return false if the github API response does not include a version file' do
      allow(client).to receive(:pull_request_files).and_return(['foo.txt'])
      expect(action.version_changed?(1)).to be_false
    end
  end
end
