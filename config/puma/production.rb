# frozen_string_literal: true

environment 'production'

directory '/home/jccadmin/twitarr'
pidfile 'tmp/puma.pid'
bind 'unix:///home/jccadmin/twitarr/tmp/puma.sock'
quiet
workers 50
threads 20, 20
