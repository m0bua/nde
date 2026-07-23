Simple Docker Compose container based PHP + NGINX + SQL development enviroment.

Using [PHP docker containers](https://hub.docker.com/r/m0bua/php/).

## d.sh

`d.sh` is the main command wrapper for the environment. With no arguments it
starts the environment when it is stopped, or opens `bash` in the default PHP
container when it is already running.

```bash
d
d up
d build
d php8
d -c 'php -v'
d h
d down
```

The complete command reference is in [d.help.md](d.help.md).

## PHP image builds

Before `d up`, the PHP base images are checked on Docker Hub. Existing
published images are reused; missing images are built from the `master` branch of
[m0bua/ci-docker-php](https://github.com/m0bua/ci-docker-php). After that,
Compose builds the local PHP layer from `cfg/php/Dockerfile`.

`ci-docker-php` is intentionally kept as a separate repository: it owns the
base PHP images, while NDE owns the complete development environment. The
published `m0bua/php` images are the normal dependency; cloning and building
`master` is only a fallback for a missing image.

When a fallback build is needed, a shallow clone is cached in
`~/.cache/nde/ci-docker-php` and refreshed once a week. The interval can be
changed with `PHP_UPSTREAM_CACHE_TTL` in `cfg/.env` (in seconds).

The default images are `php:8-fpm-alpine`, `php:7-fpm-alpine`, and
`php:5-fpm-alpine`. The list can be overridden, for example:

```bash
PHP_IMAGES='php:8-fpm-alpine php:7-fpm-alpine' d up
```

The upstream repository can be overridden with
`PHP_UPSTREAM_REPOSITORY`; the branch is always `master`.

Shell scripts can be checked with:

```bash
./lint.sh
```

## License
The repo is released under the [MIT](https://github.com/m0b-ua/nde/blob/master/LICENSE) license.
