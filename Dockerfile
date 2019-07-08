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
    libmemcached-dev \
    libz-dev \
    libpq-dev \
    libssl-dev \
    libmcrypt-dev \
    zip \
    unzip \
    nano \
    supervisor \
    && ( \
        cd /tmp \
        && mkdir librdkafka \
        && cd librdkafka \
        && git clone https://github.com/edenhill/librdkafka.git . \
        && ./configure \
        && make \
        && make install \
    ) \
  && rm -rf /var/lib/apt/lists/*

# PHP extensions
RUN docker-php-ext-install -j$(nproc) pdo_mysql \
  && docker-php-ext-install -j$(nproc) pdo_pgsql \
  && pecl install rdkafka \
  && docker-php-ext-enable rdkafka

# Suppervisor
ARG SUPERVISOR_WORKERS=/var/www/html/workers/*.conf
ENV SUPERVISOR_WORKERS ${SUPERVISOR_WORKERS}
COPY supervisord.conf /etc/supervisor/supervisord.conf

# Setup php configuration
COPY php.ini /usr/local/etc/php/php.ini

# Setup custom php-fpm www configuration
COPY www.conf /usr/local/etc/php-fpm.d/z.www.conf