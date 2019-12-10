FROM php:5-fpm

RUN apt-get update -y &&\
	apt-get install -y libfreetype6-dev libpng-dev libwebp-dev libjpeg62-turbo-dev libmagickwand-dev \
		git unzip libzip-dev libbz2-dev libxpm-dev libicu-dev libedit-dev libxml2-dev libpq-dev &&\
	apt-get dist-upgrade -y && apt-get clean &&\
	for module in gd bcmath exif iconv mysqli intl mysqli pgsql pdo pdo_pgsql pdo_mysql zip bz2 opcache soap; do \
		if [ -z "$(php -m|grep -i $module)" ];then docker-php-ext-install $module;fi;done &&\
	if [ -z "$(php -m|grep -i imagick)" ];then pecl install imagick && docker-php-ext-enable imagick;fi &&\
	if [ -z "`cat /usr/local/etc/php-fpm.d/www.conf | grep "^php_flag\[display_errors\] = on"`" ]; then \
		echo 'php_flag[display_errors] = on' >> /usr/local/etc/php-fpm.d/www.conf; fi &&\
	if [ -z "`cat /usr/local/etc/php-fpm.d/www.conf | grep "^catch_workers_output = yes"`" ]; then \
		echo 'catch_workers_output = yes' >> /usr/local/etc/php-fpm.d/www.conf; fi &&\
	if [ -z "`cat /usr/local/etc/php-fpm.d/www.conf | grep "^php_admin_flag\[log_errors\] = on"`" ]; then \
		echo 'php_admin_flag[log_errors] = on' >> /usr/local/etc/php-fpm.d/www.conf; fi &&\
	if [ -z "`cat /usr/local/etc/php/php.ini | grep "^error_reporting"`" ]; then \
		echo 'error_reporting = -1' >> /usr/local/etc/php/php.ini; fi &&\
	if [ -z "`cat /usr/local/etc/php/php.ini | grep "^display_errors"`" ]; then \
		echo 'display_errors = on' >> /usr/local/etc/php/php.ini; fi &&\
	if [ -z "`cat /usr/local/etc/php/php.ini | grep "^display_startup_errors"`" ]; then \
		echo 'display_startup_errors = on' >> /usr/local/etc/php/php.ini; fi &&\
	if [ -z "`cat /usr/local/etc/php/php.ini | grep "^upload_max_filesize"`" ]; then \
		echo 'upload_max_filesize = 100M' >> /usr/local/etc/php/php.ini; fi &&\
	if [ -z "`cat /usr/local/etc/php/php.ini | grep "^post_max_size"`" ]; then \
		echo 'post_max_size = 100M' >> /usr/local/etc/php/php.ini; fi &&\
	if [ -z "`cat /usr/local/etc/php/php.ini | grep "^memory_limit"`" ]; then \
		echo 'memory_limit = 512M' >> /usr/local/etc/php/php.ini; fi &&\
	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer &&\
	mkdir -p /.composer && chown 1000:1000 /.composer && mkdir -p /run/sock && chown 1000:1000 /run/sock &&\
	if [ -z "$(php -m|grep -i xdebug)" ];then pecl install xdebug-2.5.5 && docker-php-ext-enable xdebug;fi

WORKDIR /var/www
CMD ["php-fpm"]
