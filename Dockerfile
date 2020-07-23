FROM ruby:2.6.5

LABEL maintainer="simplybusiness/silversmiths <applicationtooling@simplybusiness.co.uk>"

COPY . .

RUN chmod +x entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
