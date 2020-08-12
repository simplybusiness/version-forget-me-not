FROM ruby:2.6.5

LABEL maintainer="simplybusiness <opensourcetech@simplybusiness.co.uk>"

ENV BUNDLER_VERSION="2.1.4"

RUN gem install bundler --version "${BUNDLER_VERSION}"

RUN mkdir -p /github/workspace

COPY Gemfile /github/workspace/

COPY entrypoint.sh /github/workspace/

COPY lib /github/workspace/lib

COPY run.rb /github/workspace/

WORKDIR /github/workspace

RUN bundle install --retry 3

RUN chmod +x /github/workspace/run.rb

ENTRYPOINT ["ruby", "run.rb"]
