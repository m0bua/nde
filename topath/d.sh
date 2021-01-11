#!/bin/bash
default_container=php

run () {
  $command $params $extra_params
  if [[ $exit == 'true' ]]; then exit; fi
}
cd $(dirname $(dirname $(realpath ${BASH_SOURCE[0]})))

command="docker-compose"
params="$*"
extra_params=""
exit=true

if [[ $params == '-init' ]]; then ./init.sh script; exit; fi

if [[ $1 == -purge ]]; then
  echo " Stopping NDE:"
  params="down"; exit='false'; run
  command='docker'
  echo " Killing all running containers:"
  extra_params=$(docker ps -q)
  if [[ $extra_params =~ [\w\d]+ ]]; then
    params='kill'; exit='false'; run
  else echo "   No containers to kill."; fi
  echo " Removing all containers:"
  extra_params=$(docker ps -aq)
  if [[ $extra_params =~ [\w\d]+ ]]; then
    params='rm'; exit='false'; run
  else echo "   No containers to remove."; fi
  echo " Removing all images:"
  extra_params=$(docker images -q)
  if [[ $extra_params =~ [\w\d]+ ]]; then
    params='rmi --force'; exit='false'; run
  else echo "   No images to remove."; fi
  exit;
fi

if [[ $1 == -delete ]]; then
  echo " Stopping NDE:"
  params="down"; exit='false'; run
  command='docker'
  echo " Killing all running containers:"
  extra_params=$(docker ps -q)
  if [[ $extra_params =~ [\w\d]+ ]]; then
    params='kill'; exit='false'; run
  else echo "   No containers to kill."; fi
  echo " Removing all containers:"
  extra_params=$(docker ps -aq)
  if [[ $extra_params =~ [\w\d]+ ]]; then
    params='rm'; exit='false'; run
  else echo "   No containers to remove."; fi
  exit;
fi

if [[ $1 == -kill ]]; then
  echo " Stopping NDE:"
  params="down"; exit='false'; run
  if [[ $(docker ps -q) =~ [\w\d]+ ]]; then
    command='docker';$params="kill $(docker ps -q)"
  else echo "   No containers to kill"; exit
fi; fi

if [[ ! -z $1 ]]; then default_container=$1; fi
params=$(docker ps --format {{.Names}} 2> /dev/null \
  | grep -E "^.*$default_container" | sort | head -n 1)

if [[ ! -z $params ]]; then
  command="docker exec -it"
  extra_params="bash"
  if [[ $2 =~ [^\s]+ ]]; then extra_params=$2; fi
elif [[ -z "$(docker ps --format {{.Names}} 2> /dev/null)" ]] \
  && [[ -z $1 ]];then params="up"; extra_params="-d"
else params="$*"; fi

if [[ $1 == df ]]; then docker system df; exit; fi
if [[ $params =~ halt ]]
  then params=$(echo $params | sed 's/halt/down/'); fi
if [[ $params =~ ^up.*-a ]]; then params=$(echo $params | sed 's/ -a//')
elif [[ $params =~ ^up ]] && [[ ! $params =~ -d ]]
  then extra_params='-d'; fi

run
