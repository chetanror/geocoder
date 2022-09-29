FROM ruby:2.7.1
LABEL maintainer="StackShare Engineering"

RUN echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/90stackshare \
  && echo 'DPkg::Options "--force-confnew";' >> /etc/apt/apt.conf.d/90stackshare

ENV DEBIAN_FRONTEND=noninteractive

RUN wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" >> /etc/apt/sources.list.d/pgdg.list

RUN apt-get update \
  && apt-get install -y locales vim git make \
  gcc g++ libpq-dev libjemalloc-dev dumb-init \
  postgresql-client-11 ca-certificates openssl \
  && rm -rf /var/lib/apt/lists/*

RUN update-ca-certificates --fresh

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" >> /etc/apt/sources.list.d/yarn.list

RUN apt-get update \
  && apt-get install -y nodejs yarn \
  && rm -rf /var/lib/apt/lists/*

RUN node -v && yarn -v

ENV LD_PRELOAD /usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# set timezone to UTC
RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime

# use unicode
RUN locale-gen C.UTF-8 || true
ENV LANG=C.UTF-8

RUN curl -sSL https://sdk.cloud.google.com | bash
ENV PATH $PATH:/root/google-cloud-sdk/bin

RUN gem install bundler:2.1.4

RUN mkdir -p /stackshare
WORKDIR /stackshare

COPY Gemfile      .
COPY Gemfile.lock .

ENV BUNDLE_GEMS__CONTRIBSYS__COM "3e37d2e4:67218b7f"

RUN bundle config set without 'development test'
RUN bundle install -j $(nproc) --retry=4

COPY . .

ENV RAILS_ENV production
ENV RAKE_ENV production
ENV STACK_DATABASE_NAME=db_name
ENV STACK_DATABASE_USERNAME=db_username
ENV STACK_DATABASE_PASSWORD=db_password
ENV STACK_DATABASE_HOST=db_host
ENV REDIS_HOST_URL=redis_host
ENV REDIS_PASSWORD=redis_password
ENV RAILS_MASTER_KEY=976591ae1d91514d6929bca6d79c7983
ENV CLEARBIT_KEY=clearbit_key
ENV GITHUB_USERNAME=username
ENV GITHUB_TOKEN=key
ENV RAILS_MAX_THREADS=10
ENV COMPREHEND_ACCESS_KEY_ID=id
ENV COMPREHEND_SECRET_ACCESS_KEY=key
ENV SS_DATABASE_URL=postgres://stackshare:password@production-cluster.cluster-ro-cpe12eci0hyg.us-east-1.rds.amazonaws.com:5432/leanstack_production
ENV WAPPALYZER_LIGHT_URL=http://host
ENV PORT 5000

RUN ASSET_PRECOMPILE=1 RAILS_ENV=production bundle exec rake assets:precompile

EXPOSE 5000

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

EXPOSE "C:\LogMonitor.exe" "C:\ServiceMonitor.exe" "w3svc" "DefaultAppPool"
