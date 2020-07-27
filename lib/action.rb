# frozen_string_literal: true

require 'octokit'

# Fetch and check the version
class Action
  attr_reader :client, :repo

  SEMVER_VERSION =
    /["'](0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?["']/.freeze

  def initialize(owner:, repo_name:, client: nil)
    @client = client || Octokit::Client.new(access_token: ENV['BOT_TOKEN'])
    @repo = "#{owner}/#{repo_name}"
  end

  def version_changed?(pull_number)
    client.pull_request_files(repo, pull_number).include?(ENV['VERSION_FILE_PATH'])
  end

  private

  def fetch_version(ref:)
    file = client.contents(repo, path: ENV['VERSION_FILE_PATH'], query: { ref: ref })
    file.match(SEMVER_VERSION)[0]
  end
end
