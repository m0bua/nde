#!/bin/bash
default_container=php

run () {
  if [[ $quoted_extra_params == 'true' ]]; then
    $command $params "$extra_params"
  else
    $command $params $extra_params
  fi
  if [[ $exit == 'true' ]]; then exit; fi
}

fn_purge () {
  fn_delete
  extra_params=$(docker images -q)
  if [[ $extra_params =~ [\w\d]+ ]]; then
    echo " Removing all images:"
    params='rmi --force'; run
  else echo "   No images to remove."; fi
}

fn_delete () {
  fn_kill
  extra_params=$(docker ps -aq)
  if [[ $extra_params =~ [\w\d]+ ]]; then
    echo " Removing all containers:"
    params='rm'; run
  else echo "   No containers to remove."; fi
}

fn_kill () {
  fn_stop
  command='docker'
  exit='false'
  extra_params=$(docker ps -q)
  if [[ $extra_params =~ [\w\d]+ ]]; then
    echo " Killing all running containers:"
    params='kill'; run
  else echo "   No containers to kill."; fi
}

fn_stop () {
  echo " Stopping NDE"
  params='down'; exit='false'; run
}

path=$(dirname $(dirname $(realpath ${BASH_SOURCE[0]})));
config=${path}/docker-compose.yml

set -e
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null ; then
    export XDEBUG_ADDRESS=$(hostname -I)
fi
export USER_NAME=$(id -un)
export GROUP_NAME=$(id -gn)
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)

command="docker-compose -f ${config}"
params="$*"
extra_params=""
params_array=( "$@" )
exit=true
quoted_extra_params=false

if [[ $params == '-init' ]]; then ./init.sh script; exit; fi
if [[ $params == -purge ]]; then fn_purge; exit; fi
if [[ $params == -delete ]]; then fn_delete; exit; fi
if [[ $params == -del ]]; then fn_delete; exit; fi
if [[ $params == -kill ]]; then fn_kill; exit; fi
if [[ $params == df ]]; then docker system df; exit; fi

if [[ $1 =~ ^[^-]+ ]]; then default_container=$1; fi
params=$(docker ps --format {{.Names}} -f label=com.docker.compose.project=nde 2> /dev/null \
  | grep -E "$default_container" | sort | head -n 1)

if [[ ! -z $params ]]; then
  command="docker exec -it"
  extra_params="bash"
  if [[ $2 =~ [^\s]+ ]]; then extra_params=$2; fi
elif [[ -z $params ]] && [[ -z $1 ]];then params="up"; extra_params="-d"
else params="$*"; fi

if [[ ${params_array[0]} == '-c' ]]; then
  params="$params bash -c"
  unset 'params_array[0]'
  extra_params=${params_array[*]}
  quoted_extra_params=true
fi

if [[ ${params_array[1]} == '-c' ]]; then
  params="$params bash -c"
  unset 'params_array[0]'
  unset 'params_array[1]'
  extra_params=${params_array[*]}
  quoted_extra_params=true
fi

if [[ $params =~ ^up.*-a ]]; then params=$(echo $params | sed 's/ -a//')
elif [[ $params =~ ^up ]] && [[ ! $params =~ -d ]]
  then extra_params='-d'; fi

if [[ $params =~ ^up ]] && [[ $params =~ -o ]]; then
  params=$(echo $params | sed 's/ -o//')
  tmp_params=$params; tmp_command=$command; tmp_extra_params=$extra_params
  extra_params=''
  ps=$(docker ps -q); if [[ $ps =~ [\w\d]+ ]]; then
    command='docker';params="stop $ps"; exit='false'; run
  fi
  ps=$(docker ps -q); if [[ $ps =~ [\w\d]+ ]]; then
    command='docker';params="kill $ps"; run
  fi
  params=$tmp_params; command=$tmp_command; extra_params=$tmp_extra_params
fi

run
