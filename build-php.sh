#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$script_dir/cfg/.env" ]]; then
    source "$script_dir/cfg/.env"
fi

UPSTREAM_REPOSITORY="${PHP_UPSTREAM_REPOSITORY:?PHP_UPSTREAM_REPOSITORY is not set in cfg/.env}"
UPSTREAM_REF="master"
UPSTREAM_CACHE_TTL="${PHP_UPSTREAM_CACHE_TTL:-604800}"

mapfile -t php_images < <(
    sed -nE 's/^[[:space:]]+IMAGE:[[:space:]]*([^[:space:]]+).*$/\1/p' \
        "$script_dir/docker-compose.yml" | sort -u
)

if ((${#php_images[@]} == 0)); then
    echo "No PHP images found in docker-compose.yml" >&2
    exit 1
fi

cache_root="${XDG_CACHE_HOME:-${HOME}/.cache}/nde"
upstream_dir="$cache_root/ci-docker-php"
cache_stamp="$cache_root/ci-docker-php.updated"

mkdir -p "$cache_root"

refresh_upstream_cache() {
    local now stamp_age

    if [[ -f "$cache_stamp" ]]; then
        now="$(date +%s)"
        stamp_age=$((now - $(stat -c %Y "$cache_stamp")))
        if ((stamp_age < UPSTREAM_CACHE_TTL)); then
            return 0
        fi
    fi

    if [[ -d "$upstream_dir/.git" ]]; then
        echo "Updating ${UPSTREAM_REPOSITORY} (${UPSTREAM_REF})"
        git -C "$upstream_dir" remote set-url origin "$UPSTREAM_REPOSITORY"
        if git -C "$upstream_dir" fetch --depth 1 origin "$UPSTREAM_REF" >/dev/null 2>&1 \
            && git -C "$upstream_dir" checkout --detach FETCH_HEAD >/dev/null 2>&1; then
            touch "$cache_stamp"
            return 0
        fi

        if [[ -f "$upstream_dir/Dockerfile" ]]; then
            echo "Using stale cached ${upstream_dir}" >&2
            return 0
        fi
    else
        echo "Cloning ${UPSTREAM_REPOSITORY} (${UPSTREAM_REF})"
        if git clone --depth 1 --branch "$UPSTREAM_REF" "$UPSTREAM_REPOSITORY" \
            "$upstream_dir" >/dev/null 2>&1; then
            touch "$cache_stamp"
            return 0
        fi
    fi

    echo "Unable to prepare ${upstream_dir}" >&2
    exit 1
}

for image in "${php_images[@]}"; do
    base_image="m0bua/${image}"

    if [[ -n "$(docker ps -q --filter "ancestor=${base_image}")" ]]; then
        echo "Using running container based on ${base_image}"
        continue
    fi

    if docker image inspect "$base_image" >/dev/null 2>&1; then
        continue
    fi

    if docker pull "$base_image" >/dev/null 2>&1; then
        echo "Using published ${base_image}"
        continue
    fi

    refresh_upstream_cache
    if [[ ! -f "$upstream_dir/Dockerfile" ]]; then
        echo "Upstream Dockerfile was not found in $upstream_dir" >&2
        exit 1
    fi

    echo "Published ${base_image} is unavailable; building it from ${UPSTREAM_REF}"
    docker buildx build \
        --load \
        --pull \
        --no-cache \
        --tag "$base_image" \
        --build-arg "IMAGE=${image}" \
        "$upstream_dir"
done
