FROM ruby:2.6.5

LABEL maintainer="simplybusiness <opensourcetech@simplybusiness.co.uk>"

ENV BUNDLER_VERSION="2.1.4"

RUN gem install bundler --version "${BUNDLER_VERSION}"

RUN mkdir -p action

COPY Gemfile action/

COPY entrypoint.sh action/

COPY lib action/lib

COPY run.rb action/

WORKDIR action

RUN bundle install --retry 3

RUN chmod +x run.rb

ENTRYPOINT ruby run.rb
