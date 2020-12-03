# frozen_string_literal: true

require 'ostruct'
require_relative '../lib/action'

describe Action do # rubocop: disable Metrics/BlockLength
  let(:client) { instance_double(Octokit::Client) }
  let(:config) do
    OpenStruct.new(
      client: client,
      file_path: 'version.rb',
      event_payload: {
        'repository' => { 'full_name' => 'simplybusiness/test' },
        'pull_request' => {
          'number' => 1,
          'head' => { 'branch' => 'my_branch', 'sha' => '1111' },
          'base' => { 'branch' => 'master' }
        }
      }
    )
  end

  let(:action) { Action.new(config) }

  describe '#check_version' do
    it 'creates a success state when version is changed' do
      allow(action).to receive(:version_changed?).and_return(true)
      expect(client).to receive(:create_status).with('simplybusiness/test',
                                                     '1111',
                                                     'success',
                                                     context: 'Gem Version',
                                                     description: 'Updated')
      action.check_version
    end

    it 'creates a failure state when version is not changed' do
      allow(action).to receive(:version_changed?).and_return(false)
      expect(client).to receive(:create_status).with('simplybusiness/test',
                                                     '1111',
                                                     'failure',
                                                     context: 'Gem Version',
                                                     description: "Update: #{config.file_path}")
      action.check_version
    end
  end

  describe '#version_changed?' do
    it 'return false when version file not changed' do
      allow(action).to receive(:version_file_changed?).and_return(false)
      expect(action.version_changed?).to be false
    end

    it 'return false when version is not increased' do
      allow(action).to receive(:version_file_changed?).and_return(true)
      allow(action).to receive(:version_increased?).and_return(false)
      expect(action.version_changed?).to be false
    end

    it 'return true when version file and version both changed' do
      allow(action).to receive(:version_file_changed?).and_return(true)
      allow(action).to receive(:version_increased?).and_return(true)
      expect(action.version_changed?).to be true
    end
  end

  describe '#version_file_changed?' do
    it 'return true if the github API response includes a version file' do
      allow(client).to receive(:pull_request_files).and_return([
                                                                 { filename: 'version.rb' },
                                                                 { filename: 'foo.txt' }
                                                               ])
      expect(action.version_file_changed?(1)).to be true
    end

    it 'return false if the github API response does not include a version file' do
      allow(client).to receive(:pull_request_files).and_return([{ filename: 'foo.txt' }])
      expect(action.version_file_changed?(1)).to be false
    end
  end

  describe '#version_increased?' do # rubocop:disable Metrics/BlockLength
    RSpec.shared_examples 'version_increased? for all supported file types' do |new_version, result|
      context 'when the content is a version file' do
        it 'returns false if the versions match' do
          mock_version_response('master', '1.2.3')
          mock_version_response('my_branch', new_version)

          expect(action.version_increased?(branch_name: 'my_branch')).to eq(result)
        end
      end

      context 'when the content is a gemspec file' do
        it 'returns false if the versions match' do
          mock_gemspec_response('master', '1.2.3')
          mock_gemspec_response('my_branch', new_version)

          expect(action.version_increased?(branch_name: 'my_branch')).to eq(result)
        end
      end
    end

    it_behaves_like 'version_increased? for all supported file types', '1.2.3', false
    it_behaves_like 'version_increased? for all supported file types', '1.1.4', false
    it_behaves_like 'version_increased? for all supported file types', '1.2.4', true
    it_behaves_like 'version_increased? for all supported file types', '1.3.0', true
    it_behaves_like 'version_increased? for all supported file types', '2.0.0', true

    context 'when version file name has changed so old version file not found' do
      it 'returns true' do
        mock_version_response('master', '1.2.3')
        mock_version_response_error('my_branch')

        expect(action.version_increased?(branch_name: 'my_branch')).to eq(true)
      end
    end

    context 'when version file not found' do
      it 'raises exception' do
        mock_version_response_error('master')
        mock_version_response('my_branch', '1.2.3')

        expect { action.version_increased?(branch_name: 'my_branch') }.to raise_error(Octokit::NotFound)
      end
    end
  end

  describe "The failed status check's description" do
    it 'has the version file path' do
      config.file_path = 'path/to/version.rb'
      description = action.failed_status_description
      expect(description.length).to be < 140
      expect(description).to eq("Update: #{config.file_path}")
    end

    it 'truncates to 140 characters if needed' do
      config.file_path = 'a/very/large/file/path/to/get/to/the/version/file/located/in/a/random/folder/somewhere/' \
                         'in/this/repo/oh/my/gosh/its/still/going/wherever/could/the/version/be/oh/found/it/version.rb'
      description = action.failed_status_description
      expect(description.length).to eq(140)
      expect(description).to eq('Update: a/very/large/file/path/to/get/to/the/version/file/located/in/a/random/folder' \
                                '/somewhere/in/this/repo/oh/my/gosh/its/still/going/wh...')
    end

    it "doesn't truncate if the description is exactly 140 characters" do
      config.file_path = 'a/very/large/file/path/to/get/to/the/version/file/located/in/a/random/folder/somewhere/' \
                         'in/this/repo/ohh/my/gosh/its/still/version.rb'
      description = action.failed_status_description
      expect(description.length).to eq(140)
      expect(description).to eq('Update: a/very/large/file/path/to/get/to/the/version/file/located/in/a/random/folder' \
                                '/somewhere/in/this/repo/ohh/my/gosh/its/still/version.rb')
    end
  end

  private

  def mock_version_response(branch, version)
    content = {
      'content' => Base64.encode64(%(
        module TestRepo
          VERSION='#{version}'
        end
      ))
    }
    mock_response(content, branch)
  end

  def mock_gemspec_response(branch, version)
    content = {
      'content' => Base64.encode64(%(
        Gem::Specification.new do |s|
          s.name                  = "action-testing"
          s.required_ruby_version = "2.6.5"
          s.version               = "#{version}"
        end
      ))
    }
    mock_response(content, branch)
  end

  def mock_response(content, branch)
    allow(client).to receive(:contents)
      .with('simplybusiness/test', path: 'version.rb', query: { ref: branch })
      .and_return(content)
  end

  def mock_version_response_error(branch)
    allow(client).to receive(:contents)
      .with('simplybusiness/test', path: 'version.rb', query: { ref: branch })
      .and_raise(Octokit::NotFound)
  end
end
