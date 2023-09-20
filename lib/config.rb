# frozen_string_literal: true

require 'octokit'
require 'json'
# Github configurations
class Config
  attr_reader :client, :event_payload, :file_path

  def initialize
    @client = Octokit::Client.new(access_token: ENV.fetch('ACCESS_TOKEN'))
    @event_payload = JSON.parse(File.read(ENV.fetch('GITHUB_EVENT_PATH')))
    @file_path = ENV.fetch('VERSION_FILE_PATH')
  end
end
