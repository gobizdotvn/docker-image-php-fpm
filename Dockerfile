#
#--------------------------------------------------------------------------
# Image Setup
#--------------------------------------------------------------------------
#

FROM php:7.2.18-fpm

ARG SUPERVISOR_WORKERS=/var/www/html/workers/*.conf
ENV SUPERVISOR_WORKERS ${SUPERVISOR_WORKERS}

#
#--------------------------------------------------------------------------
# Software's Installation
#--------------------------------------------------------------------------
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
  && docker-php-ext-enable rdkafka \
  && pecl install redis && docker-php-ext-enable redis \
  && pecl install mongodb && docker-php-ext-enable mongodb

# Composer
RUN curl -s https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Jobber
RUN wget https://github.com/dshearer/jobber/releases/download/v1.4.4/jobber_1.4.4-1_amd64.deb -O /tmp/jobber.deb \
    && apt install -f /tmp/jobber.deb \
    && rm /tmp/jobber.deb

# Other
RUN chown -R www-data:www-data /var/www

#--------------------------------------------------------------------------
# Software's Configuration
#--------------------------------------------------------------------------

COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY php.ini /usr/local/etc/php/php.ini
COPY www.conf /usr/local/etc/php-fpm.d/z.www.conf