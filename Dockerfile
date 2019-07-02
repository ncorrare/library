FROM arm32v7/ruby:2.4-slim

COPY qemu-arm-static /usr/bin

RUN apt-get update -qq && apt-get install -y build-essential apt-utils

ENV APP_ROOT /app/jamo
RUN mkdir -p $APP_ROOT
WORKDIR $APP_ROOT
ADD Gemfile* $APP_ROOT/
RUN gem update bundler
RUN bundle install
ADD . $APP_ROOT

EXPOSE 4567
CMD ["ruby", "main.rb"]
