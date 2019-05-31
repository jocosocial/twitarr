%w[
  .ruby-version
  .rbenv-vars
  app
  config
  Gemfile
  Gemfile.lock
  tmp/restart.txt
  tmp/caching-dev.txt
].each { |path| Spring.watch(path) }
