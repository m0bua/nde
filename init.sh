#!/bin/bash
nde_path=$(dirname $(realpath ${BASH_SOURCE[0]}))

echo 'NDE init!'

topath="$nde_path/topath"
if [[ -d "$topath" ]] && [[ -f "$topath/d.sh" ]];then
  if [[ $(id -u) != 0 ]]; then
    echo 'Need sudo for symlink!'
    sudo ln -fs "$topath/d.sh" /usr/local/bin/d
  else ln -fs "$topath/d.sh" /usr/local/bin/d; fi
else echo 'Path error!' $topath; fi

if [[ -d "$nde_path/cfg" ]];then
	read -p "Rewrite configs? [yN]: " link
else link='y'; fi
if [[ $link =~ ^yes|y$ ]];then
  cp -rf $nde_path/example/* $nde_path
  sed -i 's/^#//' docker-compose.yml
fi

if [[ -f "$nde_path/cfg/nginx/cert/NdeRootCA.crt" ]];then
  read -p "Generate nginx certificates? [yN]: " crt
else crt='y'; fi
if [[ $crt =~ ^yes|y$ ]];then
  chmod +x "$nde_path/cfg/nginx/cert/cert.sh"
  cd "$nde_path/cfg/nginx/cert"
  ./cert.sh

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
fi


if [[ "$*" != 'script' ]];then read -p "Ready!"; fi
