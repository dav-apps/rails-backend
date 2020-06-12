FROM ruby:2.7.1

RUN apt-get update -qq && apt-get install -y nodejs build-essential ruby-dev libpq-dev freetds-dev

RUN mkdir -p /app
WORKDIR /app

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock

RUN bundle install

COPY . /app

EXPOSE 3000
CMD bundle exec puma -C config/puma.rb
# bundle exec sidekiq -c 5 -q default -q mailers