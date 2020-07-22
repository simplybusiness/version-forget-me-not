# frozen_string_literal: true

require_relative 'lib/action'

Action.new(Config.new).check_version
