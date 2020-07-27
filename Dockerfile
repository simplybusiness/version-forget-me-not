FROM ruby:2.6.5

LABEL maintainer="simplybusiness/silversmiths <applicationtooling@simplybusiness.co.uk>"

ENV BUNDLER_VERSION="2.1.4"

RUN gem install bundler --version "${BUNDLER_VERSION}"

RUN mkdir -p action

COPY Gemfile* entrypoint.sh  action/

COPY lib action/lib

WORKDIR action

RUN bundle install --retry 3

RUN chmod +x entrypoint.sh

ENTRYPOINT ["/action/entrypoint.sh"]
