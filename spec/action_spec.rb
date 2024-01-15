# frozen_string_literal: true

require 'ostruct'
require_relative '../lib/action'

Config = Struct.new(:client, :file_path, :event_payload)

describe Action do
  let(:client) { instance_double(Octokit::Client) }
  let(:config) do
    Config.new(
      client,
      'version.rb',
      {
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
      allow(action).to receive(:version_increased?).and_return(true)
      expect(client).to receive(:create_status).with(
        'simplybusiness/test',
        '1111',
        'success',
        context: 'Version check',
        description: 'Updated'
      )
      action.check_version
    end

    it 'creates a failure state when version is not changed' do
      allow(action).to receive(:version_increased?).and_return(false)
      expect(client).to receive(:create_status).with(
        'simplybusiness/test',
        '1111',
        'failure',
        context: 'Version check',
        description: "Update: #{config.file_path}"
      )
      action.check_version
    end

    it 'creates a failure state when version file is not found' do
      allow(action).to receive_messages(
        version_increased?: false,
        failed_description: 'Version file not found on version.rb'
      )
      expect(client).to receive(:create_status).with(
        'simplybusiness/test',
        '1111',
        'failure',
        context: 'Version check',
        description: 'Version file not found on version.rb'
      )
      action.check_version
    end
  end

  describe '#fetch_version' do
    let(:repo) { 'simplybusiness/test' }
    let(:file_path) { 'version.rb' }
    let(:ref) { 'my_branch' }
    let(:content) { "module TestRepo\n  VERSION='1.2.3'\nend\n" }
    let(:decoded_content) { Base64.encode64(content) }
    let(:expected_version) { '1.2.3' }

    before do
      allow(client).to receive(:contents)
        .with(repo, path: file_path, query: { ref: ref })
        .and_return('content' => decoded_content)
    end

    context 'when the version file exists' do
      it 'returns the version' do
        expect(action.fetch_version(ref: ref)).to eq(expected_version)
      end
    end

    context 'when the version file does not exist' do
      before do
        allow(client).to receive(:contents)
          .with(repo, path: file_path, query: { ref: ref })
          .and_raise(Octokit::NotFound)
      end

      it 'returns nil' do
        expect(action.fetch_version(ref: ref)).to be_nil
      end

      it 'sets the failed description' do
        action.fetch_version(ref: ref)
        expect(action.failed_description).to eq("Version file not found on #{ref} branch #{file_path}")
      end
    end
  end

  describe '#version_increased?' do
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
      it 'return false' do
        mock_version_response('master', '1.2.3')
        mock_version_response_error('my_branch')
        expect(action.version_increased?(branch_name: 'my_branch')).to be(false)
      end
    end

    context 'when version file not found' do
      it 'rescue exception and set failed description' do
        mock_version_response_error('master')
        mock_version_response('my_branch', '1.2.3')

        expect { action.version_increased?(branch_name: 'my_branch') }.to_not raise_error
        expect(action.failed_description).to eq('Version file not found on master branch version.rb')
      end
    end
  end

  describe 'Message' do
    it 'truncates to 140 characters if needed' do
      config.file_path = 'a/very/large/file/path/to/get/to/the/version/file/located/in/a/random/folder/somewhere/' \
                         'in/this/repo/oh/my/gosh/its/still/going/wherever/could/the/version/be/oh/found/it/version.rb'
      message = "Update: #{config.file_path}"
      description = action.send(:truncate_message, message)
      expect(description.length).to eq(140)
      expect(description).to eq(
        'Update: a/very/large/file/path/to/get/to/the/version/file/located/in/a/random/folder' \
        '/somewhere/in/this/repo/oh/my/gosh/its/still/going/wh...'
      )
    end

    it "doesn't truncate if the description is exactly 140 characters" do
      config.file_path = 'a/very/large/file/path/to/get/to/the/version/file/located/in/a/random/folder/somewhere/' \
                         'in/this/repo/ohh/my/gosh/its/still/version.rb'
      message = "Update: #{config.file_path}"
      description = action.send(:truncate_message, message)
      expect(description.length).to eq(140)
      expect(description).to eq("Update: #{config.file_path}")
    end
  end

  private

  def mock_version_response(branch, version)
    content = {
      'content' => Base64.encode64(
        %(
        module TestRepo
          VERSION='#{version}'
        end
      )
      )
    }
    mock_response(content, branch)
  end

  def mock_gemspec_response(branch, version)
    content = {
      'content' => Base64.encode64(
        %(
        Gem::Specification.new do |s|
          s.name                  = "action-testing"
          s.required_ruby_version = "2.6.5"
          s.version               = "#{version}"
        end
      )
      )
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
