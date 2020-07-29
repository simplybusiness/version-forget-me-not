#!/bin/bash

set -e

ls -ltr
env
bundle exec ruby lib/action.rb
