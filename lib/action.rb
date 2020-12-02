# frozen_string_literal: true

require_relative 'config'

# Fetch and check the version
class Action
  attr_reader :client, :repo, :pull_number, :head_branch, :head_commit, :base_branch, :file_path

  SEMVER_VERSION =
    /["'](0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?["']/.freeze # rubocop:disable Layout/LineLength
  GEMSPEC_VERSION = Regexp.new(/\.version\s*=\s*/.to_s + SEMVER_VERSION.to_s).freeze

  def initialize(config)
    @client = config.client
    @repo = config.event_payload['repository']['full_name']
    @file_path = config.file_path
    assign_pr_attributes(config.event_payload['pull_request'])
  end

  def check_version
    if version_changed?
      state = 'success'
      description = 'Updated'
    else
      state = 'failure'
      description = "Update `#{file_path}`"
    end

    client.create_status(repo, head_commit, state, description: description, context: 'Gem Version')
  end

  def version_changed?
    version_file_changed?(pull_number) && version_increased?(branch_name: head_branch, trunk_name: base_branch)
  end

  def version_file_changed?(pull_number)
    file_changed = client.pull_request_files(repo, pull_number).map { |res| res[:filename] }
    file_changed.include?(file_path)
  end

  def version_increased?(branch_name:, trunk_name: 'master')
    branch_version = fetch_version_safe(ref: branch_name)
    trunk_version = fetch_version(ref: trunk_name)
    puts branch_version ? "branch version: #{branch_version}" : 'branch version: file not found, presumed name changed'
    puts "trunk version: #{trunk_version}"

    branch_version.nil? || branch_version > trunk_version
  end

  private

  def fetch_version(ref:)
    content = Base64.decode64(client.contents(repo, path: file_path, query: { ref: ref })['content'])
    match = content.match(GEMSPEC_VERSION) || content.match(SEMVER_VERSION)

    format_version(match)
  end

  def fetch_version_safe(ref:)
    fetch_version(ref: ref)
  rescue Octokit::NotFound
    nil
  end

  def format_version(version)
    Gem::Version.new(version[0].split('=').last.gsub(/\s/, '').gsub(/\'|\"/, ''))
  end

  def assign_pr_attributes(config)
    @pull_number = config['number']
    @head_branch = config['head']['ref']
    @head_commit = config['head']['sha']
    @base_branch = config['base']['ref']
  end
end
