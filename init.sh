#!/bin/bash
ndePath=$(dirname $(realpath ${BASH_SOURCE[0]}))

if [[ ! $@ =~ 'ps1' ]]; then
  echo 'NDE init!'
fi

start=${1:-"start"}

topath="$ndePath/topath"
if [[ -d "$topath" ]] && [[ -f "$topath/d.sh" ]];then
  if [[ "$topath/d.sh" != "$(realpath /usr/local/bin/d)" ]];then
    if [[ $(id -u) != 0 ]]; then
      chmod +x "$topath/d.sh"
      echo 'Need sudo for symlink!'
      sudo ln -fs "$topath/d.sh" /usr/local/bin/d
    else ln -fs "$topath/d.sh" /usr/local/bin/d; fi
  fi
else echo 'Path error!' $topath; fi

if [[ -d "$ndePath/cfg" ]];then
	read -p "Rewrite configs? [yN]: " link
else link='y'; fi
if [[ $link =~ ^yes|y$ ]];then
  cp -rf $ndePath/example/* $ndePath
  sed -i 's/^#//' $ndePath/docker-compose.yml
fi

if [[ -f "$ndePath/cfg/nginx/cert/NdeRootCA.crt" ]];then
  read -p "Generate nginx certificates? [yN]: " crt
else crt='y'; fi
if [[ $crt =~ ^yes|y$ ]];then
  chmod +x "$ndePath/cfg/nginx/cert/cert.sh"
  cd "$ndePath/cfg/nginx/cert"
  ./cert.sh
fi

if [[ ! $@ =~ 'ps1' ]]; then
  read -p "Import nginx root certificate? [yN]: " importCrt
  if [[ $importCrt =~ ^yes|y$ ]];then
    if [[ -z `which certutil` ]]; then 
      echo "No certutil found, need sudo password to install:"
      sudo apt install libnss3-tools
    fi
    certfile="NdeRootCA.pem"
    certname="NDE Root CA"
    for certDB in $(find ~/ -name "cert8.db");do
        certutil -A -n "${certname}" -t "TCu,Cu,Tu" -i ${certfile} -d dbm:$(dirname ${certDB})
    done
    for certDB in $(find ~/ -name "cert9.db");do
        certutil -A -n "${certname}" -t "TCu,Cu,Tu" -i ${certfile} -d sql:$(dirname ${certDB})
    done
  fi

  if [[ "$*" != 'script' ]];then read -p "Ready!"; fi
fi
