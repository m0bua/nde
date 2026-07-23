# d.sh

`d.sh` is the command wrapper for the NDE Docker Compose environment.

## Basic usage

```text
d                       Start the environment or enter the default PHP container
d up                     Start the environment
d build                  Build Compose services
d php8                   Enter the running php8 container
d php8 bash              Run bash in the running php8 container
d -c 'php -v'            Run a command through bash in the default container
d php8 -c 'php -v'       Run a command through bash in php8
```

When no arguments are provided:

- if the environment is stopped, PHP base images are checked and missing ones
  are built, then Compose starts using the existing service images;
- if a matching container is already running, `bash` is started in it.

The default container is `php`. A container name can be selected by passing it
as the first argument.

## Options

```text
d h,  d -h,  d --help    Show this help
d df, d --df             Show Docker disk usage
d i,  d -i,  d --init    Run NDE initialization (imports certificates on Windows)
d d,  d -d,  d --down    Stop the Compose environment
d r,  d -r,  d --reload  Recreate the environment without rebuilding services
d refresh                 Recreate the environment and rebuild services
d x,  d -x,  d --delete  Remove all containers
d k,  d -k,  d --kill    Kill all running containers
d p,  d -p,  d --purge   Remove all containers and images
```

The older forms (`-init`, `-reload`, `-delete`, `-kill`, `-purge`, and their
word aliases) remain supported for compatibility but are omitted above.

## Start options

```text
d up                     Start detached by default
d up -a                  Start in the foreground
d up -o                  Stop and kill running containers before starting
```

Every `up` and `build` operation checks the PHP base image tags configured in
`docker-compose.yml`. Local and published `m0bua/php` images are used first;
only missing images are built from the `master` branch of
`m0bua/ci-docker-php`.

## Environment variables

```text
PHP_UPSTREAM_REPOSITORY  Upstream repository URL (configured in cfg/.env)
PHP_UPSTREAM_CACHE_TTL   Cache refresh interval in seconds (configured in cfg/.env)
```
