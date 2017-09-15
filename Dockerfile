FROM redis:3.2

MAINTAINER Johan Andersson <Grokzen@gmail.com>

# Some Environment Variables
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

# Install system dependencies
RUN apt-get update -qq \
    && apt-get install --no-install-recommends -yqq \
      gcc make g++ build-essential libc6-dev tcl git \
      net-tools supervisor rubygems locales gettext-base wget \
      zlib1g-dev libssl-dev libreadline-dev libgdbm-dev openssl

# Ensure UTF-8 lang and locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && ln -s /etc/locale.alias /usr/share/locale/locale.alias \
    && locale-gen
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Install ruby 2.3 (redis requires ruby > 2.1)
ARG ruby_version=2.3.5
RUN mkdir /RUBY \
    && cd /RUBY \
    && wget https://cache.ruby-lang.org/pub/ruby/2.3/ruby-${ruby_version}.tar.gz \
    && tar xvfz ruby-${ruby_version}.tar.gz \
    && cd ruby-${ruby_version} \
    && ./configure --disable-install-doc \
    && make install \
    && rm -rf /RUBY

# Install redis
ARG redis_version=3.2.9
RUN gem install redis \
    && wget -qO redis.tar.gz http://download.redis.io/releases/redis-${redis_version}.tar.gz \
    && tar xfz redis.tar.gz -C / \
    && mv /redis-$redis_version /redis \
    && cd /redis \
    && make

# Remove build dependencies
RUN apt-get purge -yqq \
      gcc make g++ build-essential libc6-dev tcl git \
      zlib1g-dev libssl-dev libreadline-dev libgdbm-dev \
    && apt-get -yqq autoremove \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /redis-conf
RUN mkdir /redis-data

COPY ./docker-data/redis-cluster.tmpl /redis-conf/redis-cluster.tmpl
COPY ./docker-data/redis.tmpl /redis-conf/redis.tmpl

# Add supervisord configuration
COPY ./docker-data/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Add startup script
COPY ./docker-data/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod 755 /docker-entrypoint.sh

EXPOSE 7000 7001 7002 7003 7004 7005 7006 7007

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["redis-cluster"]
