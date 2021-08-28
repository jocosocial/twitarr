# frozen_string_literal: true

environment 'production'

directory '/srv/app'
pidfile '/srv/app/tmp/puma.pid'
bind 'unix:///srv/app/tmp/puma.sock'
quiet
threads 8, 64
