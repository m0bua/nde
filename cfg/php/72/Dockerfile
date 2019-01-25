FROM php:7.2-fpm

RUN \
	apt-get update -y && \
	apt-get install -y unzip libfreetype6-dev libpng-dev libjpeg62-turbo-dev libmagickwand-dev libzip-dev libbz2-dev libicu-dev libedit-dev libxml2-dev libpq-dev && \
	apt-get dist-upgrade -y && \
	for module in imagick bcmath iconv mysqli intl mysqli pgsql pdo pdo_pgsql pdo_mysql zip bz2 opcache soap; do \
		if [ -z "$(php -m|grep -i $module)" ];then docker-php-ext-install $module;fi;done && \
	if [ -z "$(php -m|grep -i gd)" ];then \
		docker-php-ext-configure gd --with-freetype-dir=/usr/include/freetype2 --with-jpeg-dir=/usr/include --with-gd && \
		docker-php-ext-install gd && docker-php-ext-enable gd;fi && \ 
	pecl install imagick && docker-php-ext-enable imagick && \
	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
	mkdir -p /.composer && chown 1000:1000 /.composer && mkdir -p /run/sock && chown 1000:1000 /run/sock && \
	if [ -z "$(php -m|grep -i xdebug)" ];then pecl install xdebug-beta && docker-php-ext-enable xdebug;fi


WORKDIR /var/www
CMD ["php-fpm"]
