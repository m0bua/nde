FROM debian:stable-slim

ARG	VERSIONS='5.6 7.0 7.1 7.2 7.3 7.4'
ARG	PHPEXT='fpm curl gd bcmath exif iconv intl mysqli pgsql pdo zip bz2 opcache soap simplexml mbstring xdebug'
ARG	INSTALL='composer git sudo bash-completion unzip php-gmagick libzip-dev libbz2-dev libicu-dev libxml2-dev \
	libpng-dev libwebp-dev libjpeg62-turbo-dev libmagickwand-dev libxpm-dev libedit-dev libpq-dev'
ARG	PHP="php7.3"
ARG	PHP7="php7.4"
ARG	PHP5="php5.6"
ARG	MUID=$MUID
ARG	MGID=$MGID

RUN	apt update -y && apt install -y --no-install-recommends wget apt-transport-https lsb-release ca-certificates &&\
	wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg &&\
	echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list

RUN	for p in $(echo "$VERSIONS" | sed -E "s/(\S+)/php\1/g");do \
	INSTALL="$INSTALL $(echo "$PHPEXT" | sed -E "s/(\S+)/"$p"-\1/g")"; done &&\
	apt update -y && apt install -y --no-install-recommends  $INSTALL &&\
	apt full-upgrade -y && apt autoremove -y && apt autoclean -y

RUN	echo 'ALL ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && update-alternatives --set php /usr/bin/$PHP &&\
	cd /usr/bin && ln -fs $PHP5 php5 && ln -fs $PHP7 php7 && usermod -u $MUID www-data && groupmod -g $MGID www-data

ADD	conf /usr/cfg
RUN	cd /etc/php && for c in $(ls -d *); do p=$(echo $c | sed "s/\.//g") &&\
	ln -fs /dev/stderr /var/log/php$c-fpm.log &&\
	ln -fs /usr/cfg/php.ini $c/fpm/php.ini && ln -fs /usr/cfg/xdebug.ini $c/mods-available/xdebug.ini &&\
	sed "s/php.sock/php"$p".sock/g" /usr/cfg/www.conf > $c/fpm/pool.d/www.conf; done
	
RUN	echo '#!/bin/bash' > /usr/cmd && chmod +x /usr/cmd &&\
	echo 'for c in /etc/init.d/php*-fpm;do $c start && $c status; done' >> /usr/cmd &&\
	echo 'ln -fs /run/php/$(echo '$PHP5'|sed "s/\.//g").sock /run/php/php5.sock' >> /usr/cmd &&\
	echo 'ln -fs /run/php/$(echo '$PHP7'|sed "s/\.//g").sock /run/php/php7.sock' >> /usr/cmd &&\
	echo 'ln -fs /run/php/$(echo '$PHP'|sed "s/\.//g").sock /run/php/php.sock' >> /usr/cmd &&\
	echo 'while [ ! -z "$(ps x | grep -E php/[0-9.]+/fpm)" ]; do sleep 1; done' >> /usr/cmd

WORKDIR	/var/www
CMD	/usr/cmd
