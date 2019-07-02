FROM ruby:2.4-slim
RUN apt-get update -qq && apt-get install -y build-essential

ENV APP_ROOT /app/jamo
RUN mkdir -p $APP_ROOT
WORKDIR $APP_ROOT
ADD Gemfile* $APP_ROOT/
RUN bundle install
ADD . $APP_ROOT

EXPOSE 4567
CMD ["ruby", "main.rb"]
