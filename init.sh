#!/usr/bin/env bash

ndePath=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
certDir="$ndePath/cfg/nginx/cert"
isYes() [[ "${1:-}" =~ ^([yY]|[yY][eE][sS])$ ]]

if git -C "$ndePath" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  oldHead=$(git -C "$ndePath" rev-parse HEAD)
  git -C "$ndePath" pull --ff-only || {
    echo 'Could not update the repository.' >&2
    exit 1
  }
  newHead=$(git -C "$ndePath" rev-parse HEAD)
  if [[ "$oldHead" != "$newHead" ]]; then
    exec bash "$ndePath/init.sh" "$@"
  fi
fi

if [[ "${1:-}" != ps1 ]]; then
  echo 'NDE init!'
fi

topath="$ndePath/topath"
if [[ -d "$topath" && -f "$topath/d.sh" ]]; then
  if [[ "$(readlink -f /usr/local/bin/d 2>/dev/null)" != "$(realpath "$topath/d.sh")" ]]; then
    chmod +x "$topath/d.sh"
    if [[ $(id -u) -ne 0 ]]; then
      echo 'Need sudo for symlink!'
      sudo ln -fs "$topath/d.sh" /usr/local/bin/d
    else
      ln -fs "$topath/d.sh" /usr/local/bin/d
    fi
  fi
else
  echo "Path error! $topath"
fi

if [[ -d "$ndePath/cfg" ]]; then
  read -r -p 'Delete cfg and recreate it? [yN]: ' link
  if isYes "$link"; then
    rm -rf -- "$ndePath/cfg"
  fi
else
  link=y
fi
if [[ ! -d "$ndePath/cfg" ]]; then
  cp -rf "$ndePath/example/." "$ndePath/"
  sed -i 's/^#//' "$ndePath/docker-compose.yml"
fi

if [[ -f "$certDir/NdeRootCA.crt" ]]; then
  read -r -p 'Generate nginx certificates? [Yn]: ' crt
  [[ -z "$crt" ]] && crt=y
else
  crt=y
fi
if isYes "$crt"; then
  chmod +x "$certDir/cert.sh"
  (cd "$certDir" && ./cert.sh)
fi

if isYes "$crt" && \
  docker compose -f "$ndePath/docker-compose.yml" ps --status running --services 2>/dev/null |
  grep -Fxq nginx; then
  echo 'Restarting nginx to load the new certificate.'
  docker compose -f "$ndePath/docker-compose.yml" restart nginx
fi

if [[ "${1:-}" != ps1 ]]; then
  read -r -p 'Import nginx root certificate? [yN]: ' importCrt
  if isYes "$importCrt"; then
    if ! command -v certutil >/dev/null 2>&1; then
      echo 'No certutil found, need sudo password to install:'
      sudo apt install libnss3-tools
    fi

    if command -v certutil >/dev/null 2>&1; then
      certfile="$certDir/NdeRootCA.pem"
      certname='NDE Root CA'
      while IFS= read -r -d '' certDB; do
        certutil -A -n "$certname" -t 'TCu,Cu,Tu' -i "$certfile" -d "dbm:$(dirname "$certDB")"
      done < <(find "$HOME" -type f -name cert8.db -print0)
      while IFS= read -r -d '' certDB; do
        certutil -A -n "$certname" -t 'TCu,Cu,Tu' -i "$certfile" -d "sql:$(dirname "$certDB")"
      done < <(find "$HOME" -type f -name cert9.db -print0)
    fi
  fi

  if [[ "${1:-}" != script ]]; then
    read -r -p 'Ready!'
  fi
fi
