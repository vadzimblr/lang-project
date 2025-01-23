FROM php:8.3.0-fpm-alpine as base

COPY ./scripts/* /usr/local/bin/

RUN set -ex \
    && apk update && apk add \
        nano \
        bash \
        curl \
        libpng-dev \
        libzip-dev \
        wget \
    && apk add --update linux-headers \
    && /usr/local/bin/docker-install-composer \
    && docker-php-ext-install -j$(nproc) \
        gd \
        pdo_mysql \
        zip \
    && docker-php-ext-configure gd --enable-gd \
    && mkdir /var/www/html/app && chown www-data:www-data /var/www/html/app

WORKDIR /var/www/html/app

CMD ["php-fpm"]

ENTRYPOINT ["docker-php-entrypoint-override"]

FROM base as develop

ARG HOST_UID=1000

RUN set -xeuo pipefail \
    && apk add shadow \
    && pecl install xdebug && docker-php-ext-enable xdebug \
    && usermod -u "${HOST_UID}" www-data \
    && groupmod -g "${HOST_UID}" www-data \
    && chown -R www-data:www-data /var/www/html/app \
