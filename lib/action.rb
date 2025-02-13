# frozen_string_literal: true

require_relative 'config'

# Fetch and check the version
class Action
  attr_reader :client, :repo, :pull_number, :head_branch, :head_commit, :base_branch, :file_path, :failed_description

  SEMVER = /["']*(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?["']*/
  SEPARATOR = /\s*[:=]\s*/
  VERSION_KEY = /(?:^_+|^|\.|\s|"|')(?:base|version)(?:["']*|_+)/
  VERSION_SETTING = Regexp.new(VERSION_KEY.source + SEPARATOR.source + SEMVER.source, Regexp::IGNORECASE).freeze

  def initialize(config)
    @client = config.client
    @repo = config.event_payload['repository']['full_name']
    @file_path = config.file_path
    assign_pr_attributes(config.event_payload['pull_request'])
  end

  def check_version
    if version_increased?(branch_name: head_branch, trunk_name: base_branch)
      state = 'success'
      description = 'Updated'
    else
      state = 'failure'
      message = failed_description || "Update: #{file_path}"
      description = truncate_message(message)
      puts "::error path#{file_path}=title=Failure::#{message}"
    end

    client.create_status(repo, head_commit, state, description: description, context: 'Version check')
  end

  def fetch_version(ref:)
    content = Base64.decode64(client.contents(repo, path: file_path, query: { ref: ref })['content'])
    match = content.match(VERSION_SETTING)

    format_version(match)
  rescue Octokit::NotFound
    @failed_description = "Version file not found on #{ref} branch #{file_path}"
    nil
  end

  def version_increased?(branch_name:, trunk_name: 'master')
    branch_version = fetch_version(ref: branch_name)
    trunk_version = fetch_version(ref: trunk_name)
    return false if branch_version.nil? || trunk_version.nil?

    puts "::notice title=Trunk version::trunk version: #{trunk_version}"
    puts "::notice title=Branch version::branch version: #{branch_version}"
    branch_version > trunk_version
  end

  private

  def format_version(version)
    Gem::Version.new(version[0].split(SEPARATOR).last.gsub(/\s/, '').gsub(/'|"/, ''))
  end

  def assign_pr_attributes(config)
    @pull_number = config['number']
    @head_branch = config['head']['ref']
    @head_commit = config['head']['sha']
    @base_branch = config['base']['ref']
  end

  def truncate_message(text)
    text.length <= 140 ? text : "#{text[0...137]}..."
  end
end
