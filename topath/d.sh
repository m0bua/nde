#!/bin/bash
default_container=php73

run () { $command $params $extra_params; exit; }
cd $(dirname $(dirname $(realpath ${BASH_SOURCE[0]})))
params="$*"
command="docker-compose"

if [[ $params =~ halt ]]; then params=$(echo $params | sed 's/halt/down/'); run; exit; fi

if [[ $params =~ ^up.*-a ]]; then params=$(echo $params | sed 's/ -a//'); run; exit;
else if [[ $params =~ ^up ]]; then if [[ ! $params =~ -d ]]; then extra_params='-d'; run; exit; fi; fi; fi

if [[ $1 == df ]]; then docker system df; exit; fi

if [[ $1 == -kill ]]; then
  if [[ $params$(docker ps -q) =~ [\w\d]+ ]]; then docker kill $(docker ps -q)
  else echo "   No containers to kill"
fi; exit; fi

if [[ $1 == -purge ]]; then
  echo " Killing all running containers:"
  params=$(docker ps -q)
  if [[ $params =~ [\w\d]+ ]]; then docker kill $params
  else echo "   No containers to kill."; fi
  echo " Removing all containers:"
  params=$(docker ps -aq)
  if [[ $params =~ [\w\d]+ ]]; then docker rm $params
  else echo "   No containers to remove."; fi
  echo " Removing all images:"
  params=$(docker images -q)
  if [[ $params =~ [\w\d]+ ]]; then docker rmi --force  $params
  else echo "   No images to remove."; fi
  exit;
fi

if [[ -z $1 ]]; then params=$(docker ps --format {{.Names}} | grep -E "^nde-.*$default_container" | head -n 1)
else params=$(docker ps --format {{.Names}} | grep -E "^nde-.*$1" | head -n 1); fi

if [[ ! -z $params ]]; then 
  command="docker exec -it"
  extra_params="bash"
  if [[ $2 =~ [^\s]+ ]]; then extra_params=$2; fi
elif [[ -z "$(docker ps --format {{.Names}})" ]]
  then params="up"; extra_params="-d"
else params="$*"; fi

run
