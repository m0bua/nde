ARG	cont
FROM ${cont}

RUN apt-get update && apt-get install -y libmagickwand-dev --no-install-recommends ghostscript \
	&& yes '' | pecl install imagick && docker-php-ext-enable imagick \
	&& sed -i 's/none/read|write/' /etc/ImageMagick-*/policy.xml

WORKDIR /var/www
CMD ["php-fpm"]