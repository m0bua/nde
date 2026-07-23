#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "$script_dir/../../.." && pwd)"
compose_file="$project_dir/docker-compose.yml"

is_yes() {
    [[ "${1:-}" =~ ^(yes|y)$ ]]
}

if [[ -f "$script_dir/NdeRootCA.crt" ]]; then
    read -r -p 'Update RootCA? [yN]: ' update_root
else
    update_root='y'
fi

if is_yes "$update_root"; then
    printf '\n   Updating RootCA...\n'

    openssl req -x509 -nodes -new -sha256 -days 1024 \
        -newkey rsa:2048 \
        -keyout "$script_dir/NdeRootCA.key" \
        -out "$script_dir/NdeRootCA.pem" \
        -subj '/C=UA/CN=NDE-Root-CA'
    openssl x509 -outform pem \
        -in "$script_dir/NdeRootCA.pem" \
        -out "$script_dir/NdeRootCA.crt"
fi

mapfile -t php_services < <(
    docker compose -f "$compose_file" config --services |
        awk '/^php[0-9]*$/ { print }'
)

if ((${#php_services[@]} == 0)); then
    echo 'No PHP services found in docker-compose.yml' >&2
    exit 1
fi

printf '\n   Updating Nginx self-signed certificate...\n'

domains_file="$script_dir/domains.txt"
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
    -keyout "$script_dir/nginx-selfsigned.key" \
    -out "$script_dir/nginx-selfsigned.csr" \
    -subj '/C=UA/ST=Ukraine/L=Kyiv/O=NDE-Certificates/CN=NDE-Selfsigned'
openssl x509 -req -sha256 -days 1024 \
    -in "$script_dir/nginx-selfsigned.csr" \
    -CA "$script_dir/NdeRootCA.pem" \
    -CAkey "$script_dir/NdeRootCA.key" \
    -CAcreateserial \
    -extfile "$domains_file" \
    -out "$script_dir/nginx-selfsigned.crt"

rm -f "$script_dir/nginx-selfsigned.csr"
