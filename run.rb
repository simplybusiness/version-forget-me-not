# frozen_string_literal: true

require_relative 'lib/action'
require_relative 'lib/config'

result = Action.new(Config.new).version_changed?
puts "Version Changed: #{result}"
raise 'Version is not changed' unless result
