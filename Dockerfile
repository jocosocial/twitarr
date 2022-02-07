# A distro upgrade requires changes here and in docker-prereqs.sh
FROM ruby:3.1.0-bullseye

COPY Gemfile* /tmp/
COPY docker-prereqs.sh /tmp/
WORKDIR /tmp

RUN ./docker-prereqs.sh

RUN gem install bundler:2.3.3

# If running in development, remove this line
RUN bundle config set without 'development test'

RUN bundle install

# set the container's time zone
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV app /srv/app
RUN mkdir $app
WORKDIR $app
ADD . $app

EXPOSE 3000

CMD [ "./start-docker.sh" ]
