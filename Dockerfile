FROM ubuntu/nginx:1.18-22.04_beta

LABEL maintainer="Radu Carjan"

ARG NODE_VERSION=16.14.2
ARG NVM_DIR=/root/.nvm
ARG WWWGROUP=1000
ARG WWWUSER=1000
ARG SERVER_ROOT=/var/www
ARG PHP_VERSION=8.1

## Set the PHP version environment variable
ENV PHP_VERSION=${PHP_VERSION}

## Add the needed config files to the image
# File to start the php-fpm service
ADD 20-php.sh /docker-entrypoint.d/         
# PHP configuration files
ADD php /usr/local/etc/php/conf.d/
# Main nginx conf file
ADD nginx/nginx.conf /etc/nginx
# Nginx sites conf files
ADD nginx/templates /etc/nginx/templates


## Set the working directory to  where the application is located
WORKDIR ${SERVER_ROOT}

ENV TZ=UTC

## Disable default site
RUN rm /etc/nginx/sites-available/default
RUN rm -rf /var/www/*

## Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    software-properties-common \
    libpng-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim \
    optipng \
    pngquant \
    gifsicle \
    vim \
    unzip \
    git \
    curl \
    netcat \
    lsof \
    net-tools \
    libmemcached-dev \
    libzip-dev \
    libpq-dev \
    nano

## Add PHP repo & install php
RUN add-apt-repository -y ppa:ondrej/php && \
    apt update

RUN apt-get install -y \
    "php${PHP_VERSION}-fpm" \
    "php${PHP_VERSION}-cli" \
    "php${PHP_VERSION}-curl" \
    "php${PHP_VERSION}-dom" \
    "php${PHP_VERSION}-mbstring"

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

## Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

## Change user UID and GID for existing user www-data
RUN usermod -u ${WWWUSER} www-data
RUN groupmod -g ${WWWGROUP} www-data

## Install NVM and Node
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install ${NODE_VERSION} \
    && nvm use --delete-prefix ${NODE_VERSION} \
    && nvm alias default v${NODE_VERSION}

## Update path variables to include node commands
ENV NODE_PATH="$NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules"
ENV PATH="${NVM_DIR}/versions/node/v${NODE_VERSION}/bin/:${PATH}"
