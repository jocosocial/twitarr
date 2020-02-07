curl -sL https://deb.nodesource.com/setup_12.x | bash -
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
echo 'deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main' > /etc/apt/sources.list.d/pgdg.list
apt-get update && apt-get install -y yarn nodejs libidn11-dev libmagickwand-dev build-essential postgresql-client libpq-dev
