#!/bin/bash

# Complete the application config while running in docker, then start rails.
#
# If you're *not* running in docker. you probably want to run `rails server` instead

set -e
set -x

# tell rails to run in production mode. comment this out if you want to run a development environment.
export RAILS_ENV=production

# uncomment this if you don't care about registration codes (like, in a dev environment)
# export DISABLE_REGISTRATION_CODES=true

# initialize the database (which we only need to do once
# comment it out once the initial db is set up, otherwise your db will be wiped every time you start docker
rails db:reset

# apply any db updates
rails db:migrate

# remove any temp files left behind by previous runs
rails tmp:clear

# precompile asset
yarn install
rails assets:precompile

# bind to all interfaces (this exposes ports out to docker)
exec rails server -b 0.0.0.0
