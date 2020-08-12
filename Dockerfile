FROM ruby:2.6.5

LABEL maintainer="simplybusiness <opensourcetech@simplybusiness.co.uk>"

ENV BUNDLER_VERSION="2.1.4"

RUN gem install bundler --version "${BUNDLER_VERSION}"


RUN mkdir -p /runner/action

WORKDIR /runner/action

COPY Gemfile* ./

COPY lib ./lib

COPY run.rb ./

RUN bundle install --retry 3

ENV BUNDLE_GEMFILE /runner/action/Gemfile

RUN chmod +x /runner/action/run.rb

ENTRYPOINT ["ruby", "/runner/action/run.rb"]
