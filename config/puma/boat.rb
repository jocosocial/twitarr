# frozen_string_literal: true

environment 'boat'

directory '/var/www/twitarr'
pidfile 'tmp/puma.pid'
bind 'unix:///var/www/twitarr/tmp/puma.sock'
quiet
threads 8, 64
