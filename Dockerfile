FROM ruby:3.3

LABEL maintainer="simplybusiness <opensourcetech@simplybusiness.co.uk>"

RUN gem update --system

RUN mkdir -p /runner/action

WORKDIR /runner/action

COPY Gemfile* ./

COPY lib ./lib

COPY run.rb ./

RUN bundle install --retry 3

ENV BUNDLE_GEMFILE /runner/action/Gemfile

RUN chmod +x /runner/action/run.rb

ENTRYPOINT ["ruby", "/runner/action/run.rb"]
