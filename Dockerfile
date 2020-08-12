FROM ruby:2.6.5

LABEL maintainer="simplybusiness <opensourcetech@simplybusiness.co.uk>"

ENV BUNDLER_VERSION="2.1.4"

RUN gem install bundler --version "${BUNDLER_VERSION}"

WORKDIR /runner

RUN mkdir -p action

COPY Gemfile action/

COPY entrypoint.sh action/

COPY lib action/lib

COPY run.rb action/



RUN bundle install --retry 3

RUN chmod +x /runner/action/entrypoint.sh

ENTRYPOINT ["/runner/action/entrypoint.sh"]
