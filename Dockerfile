FROM ruby:2.6.5

LABEL maintainer="simplybusiness <opensourcetech@simplybusiness.co.uk>"

ENV BUNDLER_VERSION="2.1.4"

RUN gem install bundler --version "${BUNDLER_VERSION}"


# RUN mkdir -p /runner/action

WORKDIR /runner


# COPY Gemfile action/

COPY entrypoint.sh ./

# COPY lib action/lib

# COPY run.rb action/



# RUN bundle install --retry 3

RUN chmod +x /runner/entrypoint.sh

ENTRYPOINT ["/runner/action/entrypoint.sh"]
