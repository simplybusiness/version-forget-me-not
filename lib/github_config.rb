# frozen_string_literal: true

require 'octokit'
require 'json'
# Github configurations
class GithubConfig
  attr_reader :client, :event_payload

  def initialize
    @client = Octokit::Client.new(access_token: ENV['BOT_TOKEN'])
    @event_payload = JSON.parse(File.read(ENV['GITHUB_EVENT_PATH']))
  end
end
