# syntax=docker/dockerfile:1
ARG RUBY_VERSION=3.4.1
FROM ruby:$RUBY_VERSION-slim

# Set working directory
WORKDIR /rails

# Install packages for Rails dev environment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl build-essential git libpq-dev libyaml-dev pkg-config nodejs yarn \
      libvips && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# Install bundler
RUN gem install bundler

# Copy gem files and install all gems (including development)
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the whole app
COPY . .

# Precompile bootsnap for faster boot
RUN bundle exec bootsnap precompile app/ lib/

# Expose Rails port
EXPOSE 3000

# Default command (can be overridden in docker-compose)
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
