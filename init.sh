#!/bin/bash
nde_path=$(dirname $(realpath ${BASH_SOURCE[0]}))

echo 'NDE init!'

topath="$nde_path/topath";
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
  read -p "Put your projects folder path: " prj_path
  if [[ -d $prj_path ]];then 
    sed -i "s|~/prj|$prj_path|g" docker-compose.yml
  else
    if [[ ! -z $prj_path ]]; then
      echo="$prj_path is not a folder. "; fi
    echo "${echo}Will keep default (~/prj)"
  fi
fi

if [[ "$*" != 'script' ]];then read -p "Ready!"; fi
