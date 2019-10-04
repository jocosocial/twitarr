# twitarr

Twit-arr is a micro-blogging site that is set up for [JoCo Cruise](https://jococruise.com/). Originally developed by [walkeriniraq](https://github.com/walkeriniraq/twitarr).

## Description

Twit-arr was the name for the Status.net instance brought onto the cruise ship for JCCC2 and JCCC3. Status.net being
less than optimal for this environment, I took it upon myself to build a new version, completely customized for
the cruise.

## Docker setup
If you're not running on linux, or just want an isolated environment, you can run twitarr in docker.

### Prereqs

You'll need the Docker [toolbox](https://www.docker.com/docker-toolbox).  I (Joey) used version 1.16.1.  The default install on a Mac is Just Fine; not sure about other platforms.

### Configuration
* Create a `secrets.yml` file based on the `secrets_example.yml` file. The tokens are just random hex strings. You can generate a secret using `rails secret`.
* If you want to run with local changes (so that you can change the Ruby code and not have to rebuild the world each time), modify docker-compose accordingly:
```
  volumes:   # Remove this for production use
   - /Users/Joey/twitarr:/srv/app
```

### Building the docker images
Run:
```
   $ docker-compose build
   $ docker-compose up
```

This will create a docker image based on ruby, as well as download a postgres image.

This can take a while to set up, as it generates the database and seed data in postgres.
Once it completes you should be able to reach twitarr via http://localhost:3000.

### Quicker startup
After running the server once, it is no longer necessary to setup the database. You should comment out the following lines in `start-docker.sh`:
```
rails db:setup
```

## Setup

You will need to make the `config/secrets.yml`.
There's already an example with some good defaults in `config/secrets_example.yml`, you just need values for your instance. You
can generate a rails secret token using the command `rails secret`.

This was originally compatible in both MRI and JRuby - in theory it still is although it might require a little effort to
get the images and crypto working in both. It is currently compatible with MRI.

## Quick Developer Setup

### Prereqs

You will need `ruby` installed.  The easiest way to do this is to install it via [RVM](http://rvm.io/).

To install [RVM](http://rvm.io/) run:

```
  $ \curl -sSL https://get.rvm.io | bash -s stable
```

Then install `ruby` via [RVM](http://rvm.io/):

```
  $ rvm install ruby-2.6.5
```

Once it's installed, rvm should automatically detect that ruby 2.6.5 should be used for this project. If it doesn't, you can use `rvm use` to set the terminal session environment to the correct version:

```
  $ rvm use ruby-2.6.5
```

You will also need to download and run [PostgreSQL](https://www.postgresql.org/)

### Project setup
This project requires bundler version 2 or higher. Currently, version 2.0.2 is used:

```
  $ gem install bundler:2.0.2
```

Then you will need to run:

```
  $ bundle install
```

Remember to set up your secrets file: (http://guides.rubyonrails.org/v4.2/upgrading_ruby_on_rails.html#config-secrets-yml)

Then you will need to setup postgres:

```
   $ cp .env-example .env
```

If you use a non-default postgres configuration, you will need to update the environment variables in `.env`

Now you have to tell postgres to create the database.

```
  $ rails db:setup
```

This will create 20 reusable registration codes, which can be used for creating new users. The created codes are numbered, code1 through code20.

It will also create 4 users.  Each of the users' password is the same as their username.

1. kvort (code1, an admin user)
2. james (code2, a non-admin user)
3. steve (code3, a non-admin user)
4. admin (code4, another admin user)


Now we can finally run the rails server.  By default this server can be hit from [http://localhost:3000](http://localhost:3000)

```
  $ rails server
```
