FROM php:5-fpm

RUN apt-get update -y \
	&& apt-get install -y unzip sendmail libpng-dev libxml2-dev libbz2-dev libedit-dev \ 
	&& apt-get dist-upgrade -y \
	&& docker-php-ext-install bcmath json xml gd intl mbstring \
		pdo pdo_mysql zip bz2 opcache readline soap \
	&& curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
	&& mkdir -p /.composer && chown 1000:1000 /.composer


WORKDIR /var/www
CMD ["php-fpm"]