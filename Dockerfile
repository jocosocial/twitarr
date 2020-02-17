FROM ruby:2.6.5

COPY Gemfile* /tmp/
COPY docker-prereqs.sh /tmp/
WORKDIR /tmp

RUN ./docker-prereqs.sh

# If running in development, remove the --without clause
RUN gem install bundler:2.1.4 && bundle install --without development test

# set the container's time zone
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV app /srv/app
RUN mkdir $app
WORKDIR $app
ADD . $app

EXPOSE 3000

CMD [ "./start-docker.sh" ]
