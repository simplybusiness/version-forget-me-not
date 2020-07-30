# frozen_string_literal: true

require_relative 'lib/action'
require_relative 'lib/github_config'

result = Action.new(GithubConfig.new).version_changed?
puts "Version Changed: #{result}"
