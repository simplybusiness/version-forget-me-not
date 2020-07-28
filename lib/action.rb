# frozen_string_literal: true

require 'octokit'
require 'version'

# Fetch and check the version
class Action
  attr_reader :client, :repo

  SEMVER_VERSION =
    /["'](0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?["']/.freeze

  def initialize(owner:, repo_name:, client: nil)
    @client = client || Octokit::Client.new(access_token: ENV['BOT_TOKEN'])
    @repo = "#{owner}/#{repo_name}"
  end

  def version_file_changed?(pull_number)
    client.pull_request_files(repo, pull_number).include?(ENV['VERSION_FILE_PATH'])
  end

  def version_increased?(branch_name:, trunk_name: 'master')
    branch_version = fetch_version(ref: branch_name)
    trunk_version = fetch_version(ref: trunk_name)
    branch_version.compare_to(trunk_version) == branch_version
  end

  private

  def fetch_version(ref:)
    content = client.contents(repo, path: ENV['VERSION_FILE_PATH'], query: { ref: ref })
    Version.new(content.match(SEMVER_VERSION)[0].gsub(/\'/, ''))
  end
end
