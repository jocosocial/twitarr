# frozen_string_literal: true

environment 'production'

pidfile 'tmp/puma.pid'
bind 'unix:///tmp/puma.sock'
quiet
workers 24
threads 5, 5

preload_app!
on_worker_boot do
  ActiveRecord::Base.establish_connection
end
