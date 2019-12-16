FROM debian:stable-slim

ARG PHP="php7.3"
ARG PHP7="php7.4"
ARG PHP5="php5.6"
ARG VERSIONS=' 5.6 7.0 7.1 7.2 7.3 7.4'
ARG PHPEXT=' fpm dev curl gd bcmath exif iconv intl mysqli pgsql pdo zip bz2 opcache soap simplexml xdebug'
ARG MUID=${MUID}
ARG MGID=${MGID}

RUN	apt update -y && apt install -y --no-install-recommends wget apt-transport-https lsb-release ca-certificates &&\
	wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg &&\
	echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
RUN	install='sudo git bash-completion composer unzip libpng-dev libwebp-dev libjpeg62-turbo-dev \
	libmagickwand-dev libzip-dev libbz2-dev libxpm-dev libicu-dev libedit-dev libxml2-dev libpq-dev' &&\
	for p in $(echo "${VERSIONS}" | sed "s/ / php/g"); do install="${install} $(echo "$PHPEXT" | sed "s/ / "$p-"/g")"; done &&\
	apt update -y && apt install -y --no-install-recommends  ${install}
RUN	apt full-upgrade -y && apt autoremove -y && apt autoclean -y

RUN	mkdir -p /run/php && echo 'ALL ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers &&\
	update-alternatives --set php /usr/bin/${PHP} && cd /usr/bin && ln -s ${PHP5} php5 && ln -s ${PHP7} php7

RUN	if [ ! -z "${MUID}" ];then usermod -u ${MUID} www-data; fi && if [ ! -z "${MGID}" ];then groupmod -g ${MGID} www-data; fi

ADD conf /usr/cfg
RUN	cd /etc/php/ && for c in $(ls -d *); do p=$(echo $c | sed "s/\.//g") &&\
	cat /usr/cfg/www.conf | sed "s/php.sock/php"$p".sock/g" > $c/fpm/pool.d/www.conf; done &&\
	for c in /etc/php/*/fpm/php.ini; do cp /usr/cfg/php.ini $c; done &&\
	for c in /etc/php/*/mods-available/xdebug.ini; do cp /usr/cfg/xdebug.ini $c; done

RUN	echo '#!/bin/bash' > /usr/cmd && chmod +x /usr/cmd && echo 'rm /run/php/*' >> /usr/cmd &&\
	echo 'for c in /usr/sbin/php-fpm*;do $c -FR & echo $c; done; sleep 1 && chmod 777 -R /run/php' >> /usr/cmd &&\
	echo 'ln -s /run/php/'$(echo ${PHP5}|sed "s/\.//g")'.sock /run/php/php5.sock' >> /usr/cmd &&\
	echo 'ln -s /run/php/'$(echo ${PHP7}|sed "s/\.//g")'.sock /run/php/php7.sock' >> /usr/cmd &&\
	echo 'ln -s /run/php/'$(echo ${PHP}|sed "s/\.//g")'.sock /run/php/php.sock' >> /usr/cmd &&\
	echo 'while [ ! -z "$(ps x | grep -E /etc/php/[0-9.]+/fpm)" ]; do sleep 1; done' >> /usr/cmd

WORKDIR /var/www
CMD sudo /usr/cmd
