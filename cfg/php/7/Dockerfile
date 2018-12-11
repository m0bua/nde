FROM php:7-fpm

RUN apt-get update -y \
	&& apt-get install -y unzip libpng-dev libzip-dev libbz2-dev libicu-dev libedit-dev libxml2-dev \ 
	&& apt-get dist-upgrade -y \
	&& docker-php-ext-install bcmath gd intl pdo_mysql zip bz2 opcache soap \
	&& curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
	&& mkdir -p /.composer && chown 1000:1000 /.composer \
	&& pecl install xdebug-beta && docker-php-ext-enable xdebug


WORKDIR /var/www
CMD ["php-fpm"]