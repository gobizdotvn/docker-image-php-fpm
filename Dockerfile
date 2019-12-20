#
#--------------------------------------------------------------------------
# Image Setup
#--------------------------------------------------------------------------
#

FROM php:7.2.18-fpm

#
#--------------------------------------------------------------------------
# Software's Installation
#--------------------------------------------------------------------------
#
# Installing tools and PHP extentions using "apt", "docker-php", "pecl",
#

# Packages
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    libmemcached-dev \
    libz-dev \
    libpq-dev \
    libssl-dev \
    libmcrypt-dev \
    libzip-dev \
    libpng-dev \
    zip \
    unzip \
    nano \
    supervisor \
  && ( \
      cd /tmp \
      && wget --unlink -O librdkafka.zip https://github.com/edenhill/librdkafka/archive/v1.3.0.zip \
      && unzip librdkafka.zip \
      && cd librdkafka-1.3.0 \
      && ./configure \
      && make \
      && make install \
      && rm -rf /tmp/librdkafka.zip /tmp/librdkafka-1.3.0 \
  ) \
  && rm -rf /var/lib/apt/lists/*

# PHP extensions
RUN docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    pdo_pgsql \
    zip \
    sockets \
    bcmath \
    gd \
  && pecl install rdkafka-3.1.3 \
  && docker-php-ext-enable rdkafka

# Suppervisor
ARG SUPERVISOR_WORKERS=/var/www/html/workers/*.conf
ENV SUPERVISOR_WORKERS ${SUPERVISOR_WORKERS}
COPY supervisord.conf /etc/supervisor/supervisord.conf

# Setup php configuration
COPY php.ini /usr/local/etc/php/php.ini

# Setup custom php-fpm www configuration
COPY www.conf /usr/local/etc/php-fpm.d/z.www.conf