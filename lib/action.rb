# frozen_string_literal: true

require_relative 'github_config'

# Fetch and check the version
class Action
  attr_reader :client, :repo, :pull_number, :head_branch, :base_branch, :file_path

  SEMVER_VERSION = /["'][0-9]+\.[0-9]+\.[0-9]+["']/.freeze
  GEMSPEC_VERSION = /\.version\s*=\s*["'][0-9]+\.[0-9]+\.[0-9]+["']/.freeze

  def initialize(config)
    @client = config.client
    @repo = config.event_payload['repository']['full_name']
    config_pr = config.event_payload['pull_request']
    @pull_number = config_pr['number']
    @head_branch = config_pr['head']['ref']
    @base_branch = config_pr['base']['ref']
    @file_path = config.file_path
  end

  def version_changed?
    version_file_changed?(pull_number) && version_increased?(branch_name: head_branch, trunk_name: base_branch)
  end

  def version_file_changed?(pull_number)
    file_changed = client.pull_request_files(repo, pull_number).map { |res| res[:filename] }
    file_changed.include?(file_path)
  end

  def version_increased?(branch_name:, trunk_name: 'master')
    branch_version = fetch_version(ref: branch_name)
    trunk_version = fetch_version(ref: trunk_name)
    puts "branch version: #{branch_version}"
    puts "trunk version: #{trunk_version}"
    branch_version > trunk_version
  end

  private

  def fetch_version(ref:)
    content = Base64.decode64(client.contents(repo, path: file_path, query: { ref: ref })['content'])
    match = content.match(GEMSPEC_VERSION) || content.match(SEMVER_VERSION)

    format_version(match)
  end

  def format_version(version)
    Gem::Version.new(version[0].split('=').last.gsub(/\s/, '').gsub(/\'|\"/, ''))
  end
end
