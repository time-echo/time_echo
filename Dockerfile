# syntax=docker/dockerfile:1
ARG RUBY_VERSION=4.0.1

FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Install base packages and build tools for pg/native gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      libjemalloc2 \
      libvips \
      postgresql-client \
      build-essential \
      git \
      libpq-dev \
      pkg-config \
      libyaml-dev && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

ENV BUNDLE_PATH="/usr/local/bundle"

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy application code
COPY . .

EXPOSE 3000

ENTRYPOINT ["/rails/entrypoint.sh"]

CMD ["sh", "-c", "bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}"]
