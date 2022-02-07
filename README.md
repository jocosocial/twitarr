# twitarr

Twit-arr is a micro-blogging site that is set up for [JoCo Cruise](https://jococruise.com/). Originally developed by [walkeriniraq](https://github.com/walkeriniraq/twitarr). This version is no longer in active development, but is being kept around as a fallback. Development on the new version is currently taking place here: https://github.com/challfry/swiftarr/

## Description

Twit-arr was the name for the Status.net instance brought onto the cruise ship for JCCC2 and JCCC3. Status.net being
less than optimal for this environment, I took it upon myself to build a new version, completely customized for
the cruise.

## Docker setup
If you're not running on linux, or just want an isolated environment, you can run twitarr in docker.

### Prereqs

You'll need the Docker [toolbox](https://www.docker.com/docker-toolbox).  I (Joey) used version 1.16.1.  The default install on a Mac is Just Fine; not sure about other platforms.

### Configuration
* Create a `default_users.yml` file based on the `default_users.yml.example` file. Set the reg codes to alphanumeric strings (all uppercase). Pick strong passwords of your choice.
* Create a `master.key` file adjacent to `secrets.yml` (in the `/config` directory) containing a sufficiently long random hex string. Consider using `rails secret` to generate.
* If you want to run with local changes (so that you can change the Ruby code and not have to rebuild the world each time), modify docker-compose accordingly:
```
  volumes:   # Remove this for production use
   - ./:/srv/app
```

### Building the docker images
Run:
```
   $ docker-compose build [--no-cache]
   $ docker-compose up
   # When you're done
   $ docker-compose down [-v]
```

This will create a docker image based on ruby, as well as download a postgres image.

This can take a while to set up, as it generates the database and seed data in postgres.
Once it completes you should be able to reach twitarr via http://localhost:3000.

## Non-Docker Setup

1. Install pre-reqs

   Debian 11:

   ```
   sudo apt-get install git gnupg2 curl imagemagick libmagickwand-dev libidn11-dev libpq-dev postgresql postgresql-contrib nodejs
   ```
   
   Fedora 34:
   ```
   sudo dnf install git gnupg2 curl imagemagick ImageMagick-devel libidn-devel libpq-devel postgresql postgresql-contrib nodejs
   ```
2. Set your postgres password

   Debian 11:
   ```
   sudo -u postgres psql
   \password
   Set the password to whatever you want. Simplest is `password`
   \q
   ```
3. Install RVM. Follow the instructions at https://rvm.io/. Reload your terminal environment after installing.
4. Clone the repository, cd into it
5. If pompted by RVM, install the required version of ruby, then leave and re-enter the directory to create the gemset
   ```
   rvm install ruby-3.1.0
   ```
6. Install gems
   ```
   bundle install
   ```
7. Copy the dev environment file. If you used a different postgres password, or need ot change the postgres connection info, edit the `.env` file after copying it:
   ```
   cp .env-example .env
   ```
   Also copy the default users file, and edit it. Set the reg codes to alphanumeric strings (all uppercase). Pick strong passwords of your choice:
   ```
   cp config/default_users.yml.example config/default_users.yml
   ```
8. Populate the database
   ```
   rails db:setup
   ```
9. Run the dev server
   ```
   rails server
   ```
The database population will create 20 reusable registration codes, which can be used for creating new users. The created codes are numbered, code1 through code20. Note that codes 1 through 4 will already be used by the default users.

For these default users, the user's password is the same as the username.

1. kvort (code1, an admin user)
2. james (code2, a non-admin user)
3. steve (code3, a non-admin user)
4. admin (code4, another admin user)


By default, the dev server can be hit from http://localhost:3000
