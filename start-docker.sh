#!/bin/bash

# Complete the application config while running in docker, then start rails.
#
# If you're *not* running in docker. you probably want to run `rails server` instead

set -e
set -x

# tell rails to run in docker mode. comment this out if you want to run a development environment.
export RAILS_ENV=docker

# uncomment this if you don't care about registration codes (like, in a dev environment)
# export DISABLE_REGISTRATION_CODES=true

# initialize the database, using the production seeds
RAILS_ENV=production rails db:prepare

# remove any temp files left behind by previous runs
rails tmp:clear

# recompile asset
rails assets:clobber
rails assets:environment
rails assets:precompile

# bind to all interfaces (this exposes ports out to docker)
exec rails server -b 0.0.0.0
