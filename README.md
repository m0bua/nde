Simple Docker Compose container based PHP + NGINX + SQL development enviroment.

Using [PHP docker containers](https://hub.docker.com/r/m0bua/php/).

## PHP image builds

Before `d up`, the PHP base images are checked on Docker Hub. Existing images
are reused; missing images are built from the `master` branch of
[m0bua/ci-docker-php](https://github.com/m0bua/ci-docker-php). After that,
Compose builds the local PHP layer from `cfg/php/Dockerfile`.

The default images are `php:8-fpm-alpine`, `php:7-fpm-alpine`, and
`php:5-fpm-alpine`. The list can be overridden, for example:

```bash
PHP_IMAGES='php:8-fpm-alpine php:7-fpm-alpine' d up
```

The upstream repository can be overridden with
`PHP_UPSTREAM_REPOSITORY`; the branch is always `master`.

## License
The repo is released under the [MIT](https://github.com/m0b-ua/nde/blob/master/LICENSE) license.
