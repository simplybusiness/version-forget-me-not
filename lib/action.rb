# frozen_string_literal: true

require_relative 'config'
require 'base64'

# Fetch and check the version
class Action
  attr_reader :client, :repo, :pull_number, :head_branch, :head_commit, :base_branch, :file_path, :failed_description

  SEMVER = /
    ["']?                # Optional quotes
    (0|[1-9]\d*)         # Major version
    \.                   # Dot separator
    (0|[1-9]\d*)         # Minor version
    \.                   # Dot separator
    (0|[1-9]\d*)         # Patch version
    (?:-                 # Optional pre-release
      (
        (?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*) # Pre-release identifier
        (?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))* # Additional identifiers
      )
    )?
    (?:\+                # Optional build metadata
      (
        [0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)* # Build metadata identifiers
      )
    )?
    ["']?                # Optional quotes
  /x

  SEPARATOR = /
    \s*                  # Optional whitespace
    [:=]                 # Separator (colon or equals)
    \s*                  # Optional whitespace
  /x

  VERSION_KEY = /
    (?:^_+|^|\.|\s|"|')  # Optional prefix
    (?:base|version)     # Key name
    (?:["']*|_+)         # Optional suffix
  /x

  VERSION_SETTING = /
    #{VERSION_KEY.source} # Match version key
    #{SEPARATOR.source}   # Match separator
    #{SEMVER.source}      # Match semantic version
  /ix

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
