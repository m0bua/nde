#!/bin/bash
nde_path=$(dirname $(realpath ${BASH_SOURCE[0]}))

echo 'NDE init!'

topath="$topath/$nde_path";
if [[ -d "$topath" ]];then
  if [[ -f "$topath/d.sh" ]];then 
    ln -fs "$topath/d.sh" /usr/local/bin/d; fi
else echo 'Path error!'; fi

if [[ $nde_path != '~/nde' ]];then
  ln -fs $nde_path ~/nde; fi

read -p "Put your projects folder path: " prj_path
if [[ -d $prj_path ]];then ln -fs $prj_path ~/prj
else echo "Projects path error! Skipping..."; fi

if [[ -d "$nde_path\cfg" ]];then
read -p "Rewrite configs? [nY]: " link
else link='y'; fi
if [[ $link =~ ^yes|y$ ]];then 
  from="$nde_path/example/*"
  cp -rf $from $nde_path
fi
if [[ $args != 'script' ]];then read -p "Ready!"; fi
