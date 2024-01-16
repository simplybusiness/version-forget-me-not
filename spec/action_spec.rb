# frozen_string_literal: true

require 'ostruct'
require_relative '../lib/action'

Config = Struct.new(:client, :file_path, :event_payload)

describe Action do
  let(:client) { instance_double(Octokit::Client) }
  let(:file_path) { 'version_file_path' }
  let(:event_payload) do
    {
      'repository' => { 'full_name' => 'simplybusiness/test' },
      'pull_request' => {
        'number' => 1,
        'head' => { 'branch' => 'my_branch', 'sha' => '1111' },
        'base' => { 'branch' => 'master' }
      }
    }
  end
  let(:config) { Config.new(client, file_path, event_payload) }
  let(:action) { Action.new(config) }
  let(:repo) { 'simplybusiness/test' }
  let(:ref) { 'my_branch' }

  describe 'VERSION_SETTING' do
    it 'is case insensitive' do
      expect(Action::VERSION_SETTING).to match('VERSION=1.2.3')
      expect(Action::VERSION_SETTING).to match('version=1.2.3')
      expect(Action::VERSION_SETTING).to match('Version=1.2.3')
    end

    it 'handles SB version.rb versioning using base and an algorithm' do
      expect(Action::VERSION_SETTING).to match("base = '2.1.10'")
    end

    it 'handles extended versioning' do
      expect(Action::VERSION_SETTING).to match('VERSION=1.2.3.pre')
      expect(Action::VERSION_SETTING).to match('VERSION=1.2.3.123456')
      expect(Action::VERSION_SETTING).to match('VERSION=1.2.3-alpha')
      expect(Action::VERSION_SETTING).to match('VERSION=1.2.3+build123')
    end

    it 'handles spaces between version and number' do
      expect(Action::VERSION_SETTING).to match('VERSION = 1.2.3')
    end

    it 'handles single and double quotes' do
      expect(Action::VERSION_SETTING).to match('"VERSION" = "1.2.3"')
      expect(Action::VERSION_SETTING).to match("'VERSION' = '1.2.3'")
    end

    it 'handles colon separator' do
      expect(Action::VERSION_SETTING).to match('"VERSION": "1.2.3"')
    end

    it 'handles version stored on object' do
      expect(Action::VERSION_SETTING).to match('gem.version = 1.2.3')
    end

    it 'does not match version number only' do
      expect(Action::VERSION_SETTING).not_to match('5.5.5')
    end

    it 'does not match unrelated versioning' do
      expect(Action::VERSION_SETTING).not_to match('expected_ruby_version = 3.3.0')
    end
  end

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
        failed_description: "Version file not found on #{config.file_path}"
      )
      expect(client).to receive(:create_status).with(
        'simplybusiness/test',
        '1111',
        'failure',
        context: 'Version check',
        description: "Version file not found on #{config.file_path}"
      )
      action.check_version
    end
  end

  describe '#fetch_version' do
    it 'returns the correct version for a version.rb file' do
      mock_response('my_branch', mock_version_content('1.2.3'))

      expect(action.fetch_version(ref: ref)).to eq("1.2.3")
    end

    it 'returns the correct version for a sb algo-generated version.rb file' do
      mock_response('my_branch', mock_sb_algo_version_content('1.2.3'))

      expect(action.fetch_version(ref: ref)).to eq("1.2.3")
    end

    it 'returns the correct version for a gemspec file' do
      mock_response('my_branch', mock_gemspec_content('1.2.3'))

      expect(action.fetch_version(ref: ref)).to eq("1.2.3")
    end

    it 'returns the correct version for a openapi.yaml file' do
      mock_response('my_branch', mock_open_api_yaml_content('1.2.3'))

      expect(action.fetch_version(ref: ref)).to eq("1.2.3")
    end

    it 'returns the correct version for a package.json file' do
      mock_response('my_branch', mock_package_json_content('1.2.3'))

      expect(action.fetch_version(ref: ref)).to eq("1.2.3")
    end

    it 'returns the correct version for a pyproject.toml file' do
      mock_response('my_branch', mock_pyproject_toml_content('1.2.3'))

      expect(action.fetch_version(ref: ref)).to eq("1.2.3")
    end

    context 'when the version file does not exist' do
      before do
        mock_response_error('my_branch')
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
    context 'when version is unchanged' do
      it 'returns false' do
        mock_response('master', mock_version_content('1.2.3'))
        mock_response('my_branch', mock_version_content('1.2.3'))

        expect(action.version_increased?(branch_name: 'my_branch')).to be(false)
      end
    end

    context 'when there is a version decrease' do
      it 'returns false' do
        mock_response('master', mock_version_content('1.2.3'))
        mock_response('my_branch', mock_version_content('1.1.24'))

        expect(action.version_increased?(branch_name: 'my_branch')).to be(false)
      end
    end

    context 'when there is a patch version increase' do
      it 'returns true' do
        mock_response('master', mock_version_content('1.2.3'))
        mock_response('my_branch', mock_version_content('1.2.4'))

        expect(action.version_increased?(branch_name: 'my_branch')).to be(true)
      end
    end

    context 'when there is a minor version increase' do
      it 'returns true' do
        mock_response('master', mock_version_content('1.2.3'))
        mock_response('my_branch', mock_version_content('1.3.0'))

        expect(action.version_increased?(branch_name: 'my_branch')).to be(true)
      end
    end

    context 'when there is a major version increase' do
      it 'returns true' do
        mock_response('master', mock_version_content('1.2.3'))
        mock_response('my_branch', mock_version_content('2.0.0'))

        expect(action.version_increased?(branch_name: 'my_branch')).to be(true)
      end
    end

    context 'when version file name has changed so old version file not found' do
      it 'returns false' do
        mock_response('master', mock_version_content('1.2.3'))
        mock_response_error('my_branch')
        expect(action.version_increased?(branch_name: 'my_branch')).to be(false)
      end
    end

    context 'when version file not found' do
      it 'rescues exception and set failed description' do
        mock_response_error('master')
        mock_response('my_branch', mock_version_content('1.2.3'))

        expect { action.version_increased?(branch_name: 'my_branch') }.to_not raise_error
        expect(action.failed_description).to eq("Version file not found on master branch #{config.file_path}")
      end
    end
  end

  describe 'message' do
    it 'truncates to 140 characters if needed' do
      config.file_path = 'a/very/large/file/path/to/get/to/the/version/file/located/in/a/random/folder' \
                         '/somewhere/in/this/repo/oh/my/gosh/its/still/going/wherever' \
                         '/could/the/version/be/oh/found/it/version_file_path'
      message = "Update: #{config.file_path}"
      description = action.send(:truncate_message, message)
      expect(description.length).to eq(140)
      expect(description).to eq(
        'Update: a/very/large/file/path/to/get/to/the/version/file/located/in/a/random/folder' \
        '/somewhere/in/this/repo/oh/my/gosh/its/still/going/wh...'
      )
    end

    it "doesn't truncate if the description is exactly 140 characters" do
      config.file_path = 'a/very/large/file/path/to/get/to/the/version/file/located/in/a/folder/somewhere/' \
                         'in/this/repo/ohh/my/gosh/its/still/version_file_path'
      message = "Update: #{config.file_path}"
      description = action.send(:truncate_message, message)
      expect(description.length).to eq(140)
      expect(description).to eq("Update: #{config.file_path}")
    end
  end

  private

  def mock_version_content(version)
    %(
      module TestRepo
        VERSION='#{version}'
      end
    )
  end

  def mock_sb_algo_version_content(version)
    %(
      module TestRepo
        base = '#{version}'

        # SB-specific versioning "algorithm" to accommodate BNW/Jenkins/gemstash
        VERSION = (pre = ENV.fetch('GEM_PRE_RELEASE', '')).empty? ? base : "\#{base}.\#{pre}"
      end
    )
  end

  def mock_gemspec_content(version)
    %(
      Gem::Specification.new do |s|
        s.name                  = "action-testing"
        s.required_ruby_version = "2.6.5"
        s.version               = "#{version}"
      end
    )
  end

  def mock_open_api_yaml_content(version)
    %(
      openapi: 3.0.0
      info:
        title: Sample API
        description: Optional multiline or single-line description in [CommonMark](http://commonmark.org/help/) or HTML.
        version: "#{version}"
    )
  end

  def mock_package_json_content(version)
    %(
      {
        "name": "action-testing",
        "version": "#{version}"
      }
    )
  end

  def mock_pyproject_toml_content(version)
    %(
      [tool.poetry]
      name = "action-testing"
      version = "#{version}"
    )
  end

  def mock_response(branch, content)
    allow(client).to receive(:contents)
      .with('simplybusiness/test', path: config.file_path, query: { ref: branch })
      .and_return({ 'content' => Base64.encode64(content) })
  end

  def mock_response_error(branch)
    allow(client).to receive(:contents)
      .with('simplybusiness/test', path: config.file_path, query: { ref: branch })
      .and_raise(Octokit::NotFound)
  end
end
