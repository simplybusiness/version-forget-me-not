FROM ruby:2.6.5

LABEL maintainer="simplybusiness/silversmiths <applicationtooling@simplybusiness.co.uk>"

ENV BUNDLER_VERSION="2.1.4"

RUN gem install bundler --version "${BUNDLER_VERSION}"

COPY . .

RUN bundle install --retry 4

RUN chmod +x entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
