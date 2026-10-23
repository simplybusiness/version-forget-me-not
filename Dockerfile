FROM ruby:3.3

LABEL maintainer="simplybusiness <opensourcetech@simplybusiness.co.uk>"
LABEL org.opencontainers.image.source="https://github.com/simplybusiness/version-forget-me-not"
LABEL org.opencontainers.image.description="GitHub Action to check version updates in pull requests"

RUN mkdir -p /runner/action

WORKDIR /runner/action

COPY Gemfile* ./

COPY lib ./lib

COPY run.rb ./

RUN bundle install --retry 3 --without development test

ENV BUNDLE_GEMFILE=/runner/action/Gemfile

RUN chmod +x /runner/action/run.rb

ENTRYPOINT ["ruby", "/runner/action/run.rb"]
