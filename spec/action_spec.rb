# frozen_string_literal: true

require 'rspec'
require_relative '../lib/action'

describe Action do
  let(:client) { instance_double(Octokit::Client) }
  let(:action) { Action.new(owner: 'simplybusiness', repo_name: 'test', client: client) }
  before { ENV['VERSION_FILE_PATH'] = 'version.rb' }

  def mock_version_response(branch, version)
    content = %(
        module TestRepo
          VERSION='#{version}'
        end
      )

    allow(client).to receive(:contents).with(
        'simplybusiness/test',
        path: ENV['VERSION_FILE_PATH'],
        query: { ref: branch }
    ).and_return(content)
  end

  describe '#version_file_changed?' do
    it 'return true if the github API response includes a version file' do
      allow(client).to receive(:pull_request_files).and_return(%w[version.rb foo.txt])
      expect(action.version_file_changed?(1)).to be true
    end

    it 'return false if the github API response does not include a version file' do
      allow(client).to receive(:pull_request_files).and_return(['foo.txt'])
      expect(action.version_file_changed?(1)).to be false
    end
  end

  describe 'version_updated?' do
    it 'returns false if the versions match' do
      mock_version_response('master', '1.2.3')
      mock_version_response('my_branch', '1.2.3')

      expect(action.version_increased?(branch_name: 'my_branch')).to be_falsey
    end

    it 'returns false if the branch is behind the trunk' do
      mock_version_response('master', '1.2.3')
      mock_version_response('my_branch', '1.1.3')

      expect(action.version_increased?(branch_name: 'my_branch')).to be_falsey
    end

    it 'returns true for a patch version bump' do
      mock_version_response('master', '1.2.3')
      mock_version_response('my_branch', '1.2.4')

      expect(action.version_increased?(branch_name: 'my_branch')).to be_truthy
    end

    it 'returns true for a minor version bump' do
      mock_version_response('master', '1.2.3')
      mock_version_response('my_branch', '1.3.0')

      expect(action.version_increased?(branch_name: 'my_branch')).to be_truthy
    end

    it 'returns true for a major version bump' do
      mock_version_response('master', '1.2.3')
      mock_version_response('my_branch', '2.0.0')

      expect(action.version_increased?(branch_name: 'my_branch')).to be_truthy
    end
  end
end
