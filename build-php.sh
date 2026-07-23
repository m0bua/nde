#!/usr/bin/env bash
set -euo pipefail

# The upstream repository is intentionally tracked by master. Both
# repositories are maintained together, so it is used only when a published
# base image is missing.
UPSTREAM_REPOSITORY="${PHP_UPSTREAM_REPOSITORY:-https://github.com/m0bua/ci-docker-php.git}"
UPSTREAM_REF="master"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Keep this list in sync with the php services in docker-compose.yml, or
# override it for a local setup:
#   PHP_IMAGES='php:8-fpm-alpine php:7-fpm-alpine' ./build-php.sh
if [[ -n "${PHP_IMAGES:-}" ]]; then
    read -r -a php_images <<< "$PHP_IMAGES"
else
    mapfile -t php_images < <(
        sed -nE 's/^[[:space:]]+IMAGE:[[:space:]]*([^[:space:]]+).*$/\1/p' \
            "$script_dir/docker-compose.yml" | sort -u
    )
fi

if ((${#php_images[@]} == 0)); then
    echo "PHP_IMAGES must contain at least one image" >&2
    exit 1
fi

work_dir="$(mktemp -d)"
cleanup() {
    rm -rf "$work_dir"
}
trap cleanup EXIT

for image in "${php_images[@]}"; do
    base_image="m0bua/${image}"

    if docker buildx imagetools inspect "$base_image" >/dev/null 2>&1; then
        echo "Using published ${base_image}"
        continue
    fi

    if [[ ! -d "$work_dir/ci-docker-php" ]]; then
        echo "Cloning ${UPSTREAM_REPOSITORY} (${UPSTREAM_REF})"
        git clone --depth 1 --branch "$UPSTREAM_REF" "$UPSTREAM_REPOSITORY" \
            "$work_dir/ci-docker-php"
    fi

    upstream_dir="$work_dir/ci-docker-php"
    if [[ ! -f "$upstream_dir/Dockerfile" ]]; then
        echo "Upstream Dockerfile was not found in $upstream_dir" >&2
        exit 1
    fi

    echo "Building ${base_image} from ${UPSTREAM_REF}"
    docker buildx build \
        --load \
        --pull \
        --no-cache \
        --tag "$base_image" \
        --build-arg "IMAGE=${image}" \
        "$upstream_dir"
done
