#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "$script_dir/.." && pwd)"
cert_dir="$project_dir/cfg/nginx/cert"
compose_file="$project_dir/docker-compose.yml"
auto_mode=false

mkdir -p "$cert_dir"

if [[ "${1:-}" == '--auto' ]]; then
    auto_mode=true
fi

is_yes() {
    [[ "${1:-}" =~ ^(yes|y)$ ]]
}

if [[ "$auto_mode" == true ]]; then
    update_root='n'
elif [[ -f "$cert_dir/NdeRootCA.crt" ]]; then
    read -r -p 'Update RootCA? [yN]: ' update_root
else
    update_root='y'
fi

if is_yes "$update_root"; then
    printf '\n   Updating RootCA...\n'

    openssl req -x509 -nodes -new -sha256 -days 1024 \
        -newkey rsa:2048 \
        -keyout "$cert_dir/NdeRootCA.key" \
        -out "$cert_dir/NdeRootCA.pem" \
        -subj '/C=UA/CN=NDE-Root-CA'
    openssl x509 -outform pem \
        -in "$cert_dir/NdeRootCA.pem" \
        -out "$cert_dir/NdeRootCA.crt"
fi

mapfile -t php_services < <(
    docker compose -f "$compose_file" config --services |
        awk '/^php[0-9]*$/ { print }' |
        sort
)

if ((${#php_services[@]} == 0)); then
    echo 'No PHP services found in docker-compose.yml' >&2
    exit 1
fi

cert_state="$cert_dir/.php-config.sha256"
php_config_hash="$(
    {
        printf '%s\n' "${php_services[@]}"
        docker compose -f "$compose_file" config | awk '
            /^  php[0-9]*:$/ { in_php=1 }
            in_php { print }
            in_php && /^  [a-zA-Z0-9_-]+:$/ && $1 !~ /^php[0-9]*:$/ { in_php=0 }
        '
    } | sha256sum | awk '{print $1}'
)"

if [[ "$auto_mode" == true && -f "$cert_state" && -f "$cert_dir/nginx-selfsigned.crt" &&
    -f "$cert_dir/nginx-selfsigned.key" && -f "$cert_dir/NdeRootCA.pem" &&
    "$(<"$cert_state")" == "$php_config_hash" ]]; then
    exit 0
fi

printf '\n   Updating Nginx self-signed certificate...\n'

domains_file="$cert_dir/domains.txt"
{
    printf '%s\n' \
        'authorityKeyIdentifier=keyid,issuer' \
        'basicConstraints=CA:FALSE' \
        'keyUsage=digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment' \
        'subjectAltName=@alt_names' \
        '[alt_names]'

    dns_index=1
    printf 'DNS.%d = localhost\n' "$dns_index"

    for service in main adminer mail; do
        ((++dns_index))
        printf 'DNS.%d = %s.local\n' "$dns_index" "$service"
    done

    for service in "${php_services[@]}"; do
        ((++dns_index))
        printf 'DNS.%d = *.%s.local\n' "$dns_index" "$service"
    done
} > "$domains_file"

openssl req -new -nodes -newkey rsa:2048 \
    -keyout "$cert_dir/nginx-selfsigned.key" \
    -out "$cert_dir/nginx-selfsigned.csr" \
    -subj '/C=UA/ST=Ukraine/L=Kyiv/O=NDE-Certificates/CN=NDE-Selfsigned'
openssl x509 -req -sha256 -days 1024 \
    -in "$cert_dir/nginx-selfsigned.csr" \
    -CA "$cert_dir/NdeRootCA.pem" \
    -CAkey "$cert_dir/NdeRootCA.key" \
    -CAcreateserial \
    -extfile "$domains_file" \
    -out "$cert_dir/nginx-selfsigned.crt"

rm -f "$cert_dir/nginx-selfsigned.csr"
printf '%s\n' "$php_config_hash" > "$cert_state"
