# frozen_string_literal: true

require 'rspec'
require_relative '../lib/action'

describe Action do
  let(:client) { instance_double(Octokit::Client) }
  let(:action) { Action.new(owner: 'simplybusiness', repo_name: 'test', client: client) }
  before { ENV['VERSION_FILE_PATH'] = 'version.rb' }

  describe '#version_changed?' do
    it 'return true if the github API response includes a version file' do
      allow(client).to receive(:pull_request_files).and_return(%w[version.rb foo.txt])
      expect(action.version_changed?(1)).to be true
    end

    it 'return false if the github API response does not include a version file' do
      allow(client).to receive(:pull_request_files).and_return(['foo.txt'])
      expect(action.version_changed?(1)).to be false
    end
  end

  describe '#fetch_version' do
    let(:content) do
      %(
        module TestRepo
          VERSION='1.2.3'
        end
      )
    end

    it 'reads the version file and return the version for a branch' do
      allow(client).to receive(:contents).with(
        'simplybusiness/test',
        path: ENV['VERSION_FILE_PATH'],
        query: { ref: 'master' }
      ).and_return(content)

      expect(action.send(:fetch_version, ref: 'master')).to eq('1.2.3')
    end
  end
end
