#!/bin/bash

# Complete the application config while running in docker, then start rails.
#
# If you're *not* running in docker. you probably want to run `rails server` instead

set -e
set -x

# setup steps (which we only need to do once - comment it out once the initial db is set up)
rails db:setup

# apply any db updates
rails db:migrate

# remove any temp files left behind by previous runs
rails tmp:clear

# bind to all interfaces (this exposes ports out to docker)
exec rails server -b 0.0.0.0
