FROM php:7.2-fpm

RUN \
	apt-get update -y && \
	apt-get install -y unzip libpng-dev libzip-dev libbz2-dev libicu-dev libedit-dev libxml2-dev && \
	apt-get dist-upgrade -y && \
	for module in bcmath gd mysqli intl pdo_mysql zip bz2 opcache soap; do \
		if [ -z "$(php -m|grep -i $module)" ];then docker-php-ext-install $module;fi;done && \
	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
	mkdir -p /.composer && chown 1000:1000 /.composer && \
	if [ -z "$(php -m|grep -i xdebug)" ];then pecl install xdebug-beta && docker-php-ext-enable xdebug;fi


WORKDIR /var/www
CMD ["php-fpm"]