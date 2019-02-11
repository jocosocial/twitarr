FROM jruby:9

COPY Gemfile* /tmp/
WORKDIR /tmp

# we're not compatible with bundler 2, so force 1.17.2
RUN gem install bundler:1.17.2 && bundle _1.17.2_ install
# todo - this warn against running as root, should we make an app user?

ENV app /srv/app
RUN mkdir $app
WORKDIR $app
ADD . $app

RUN chmod +x start-docker.sh

# these steps are done by start.sh:
# RUN cp config/mongoid-example.yml config/mongoid.yml
# RUN rake db:mongoid:create_indexes
# RUN rake db:seed

EXPOSE 3000

CMD [ "./start-docker.sh" ]