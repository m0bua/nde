#!/bin/bash
cd ~/nde

params="$*"
command="docker-compose"

if [[ $params =~ ^up.*-a ]]; then params=$(echo $params | sed 's/ -a//')
else 
	if [[ $params =~ ^up ]]; then if [[ ! $params =~ -d ]]; then extra_params='-d'
fi; fi; fi

if [[ $1 == ssh ]]; then
	command="docker exec -it"
	extra_params="bash"
	if [[ ! -z $2 ]]; then params=$(docker ps --format {{.Names}} | grep _$2 | head -n 1); fi
	if [[ ! $params =~ [\w\d_]+ ]]; then 
		if [[ $2 =~ ^[^\s]+ ]]; then extra_params=$2; fi
		params=$(docker ps --format {{.Names}} | grep _php7 | head -n 1); 
	fi
	if [[ ! $params =~ [\w\d_]+ ]]; then params=$(docker ps -a --format {{.Names}} | grep _php7 | head -n 1); fi
	if [[ $3 =~ ^[^\s]+ ]]; then extra_params=$3; fi
fi

if [[ $1 == df ]]; then
	docker system df
	exit
fi

if [[ $1 == ---kill ]]; then
	params=$(docker ps -q)
	if [[ $params =~ [\w\d]+ ]]; then docker kill $params
	else echo "   No containers to kill"
	fi
	exit;
fi

if [[ $1 == ---purge ]]; then
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


$command $params $extra_params