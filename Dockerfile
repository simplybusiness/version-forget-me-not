FROM ruby:2.6.5

LABEL maintainer="simplybusiness <opensourcetech@simplybusiness.co.uk>"

ENV BUNDLER_VERSION="2.1.4"

RUN gem install bundler --version "${BUNDLER_VERSION}"


RUN mkdir -p /runner/action

WORKDIR /runner/action

COPY Gemfile ./

COPY entrypoint.sh ./

COPY lib ./lib

COPY run.rb ./

RUN bundle install --retry 3

RUN chmod +x /runner/action/entrypoint.sh

ENTRYPOINT ["/runner/action/entrypoint.sh"]
