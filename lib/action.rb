# frozen_string_literal: true

require 'octokit'

# Fetch and check the version
class Action
  attr_reader :client, :repo

  def initialize(owner:, repo_name:, client: nil)
    @client = client || Octokit::Client.new(access_token: ENV['BOT_TOKEN'])
    @repo = "#{owner}/#{repo_name}"
  end

  def version_changed?(pull_number)
    client.pull_request_files(repo, pull_number).include?(ENV['VERSION_FILE_PATH'])
  end
end
