curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
echo 'deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main' > /etc/apt/sources.list.d/pgdg.list
apt-get update && apt-get install -y libidn11-dev libmagickwand-dev build-essential postgresql-client-13 libpq-dev nodejs
