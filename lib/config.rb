# frozen_string_literal: true

require 'octokit'
require 'json'
# Github configurations
class Config
  attr_reader :client, :event_payload

  def initialize
    @client = Octokit::Client.new(access_token: ENV['BOT_TOKEN'])
    @event_payload = JSON.parse(File.read(ENV['GITHUB_EVENT_PATH']))
    @file_path = ENV['VERSION_FILE_PATH'] || ENV['GEMSPEC_PATH']
  end
end
