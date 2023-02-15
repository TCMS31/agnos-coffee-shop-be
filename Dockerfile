# syntax=docker/dockerfile:1

# ---- build -----------------------------------------------------------------
# Compiles the native extensions (pg, nokogiri, bootsnap) with the toolchain,
# so the runtime image never has to carry a C compiler.
FROM ruby:2.7.5-slim AS build

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_DEPLOYMENT=1

RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y build-essential libpq-dev git \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v 2.4.6 \
 && bundle install \
 && rm -rf "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

# Precompile bootsnap so the first request after a deploy is not the slow one.
RUN bundle exec bootsnap precompile --gemfile app/ lib/ config/

# ---- runtime ---------------------------------------------------------------
FROM ruby:2.7.5-slim AS runtime

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_DEPLOYMENT=1 \
    RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    PORT=3000

# libpq5 is the pg client library; curl is only here for the healthcheck.
RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y libpq5 curl tzdata \
 && rm -rf /var/lib/apt/lists/*

# Runs unprivileged: a compromised worker should not own the filesystem.
RUN groupadd --system --gid 1000 coffee \
 && useradd --system --uid 1000 --gid coffee --create-home coffee

WORKDIR /app

COPY --from=build --chown=coffee:coffee /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=coffee:coffee /app /app

RUN mkdir -p tmp/pids log && chown -R coffee:coffee tmp log

USER coffee

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS "http://localhost:${PORT}/up" || exit 1

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
