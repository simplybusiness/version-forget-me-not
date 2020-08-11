# frozen_string_literal: true

require_relative 'lib/action'

puts 'hello world!'

Action.new(Config.new).check_version
