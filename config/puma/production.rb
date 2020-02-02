environment 'production'

directory '/home/jccadmin/twitarr'
pidfile 'tmp/puma.pid'
bind 'unix:///home/jccadmin/twitarr/tmp/puma.sock'
quiet
workers 8
threads 20, 20
