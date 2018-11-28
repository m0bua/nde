FROM php:5-fpm

RUN apt-get update -y && apt-get install -y git unzip sendmail libpng-dev \
	&& docker-php-ext-install pdo pdo_mysql bcmath gd zip \
	&& curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
	&& rm -rf /.composer && mkdir /.composer && chown 1000:1000 /.composer


WORKDIR /var/www
CMD ["php-fpm"]