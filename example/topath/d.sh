#!/bin/bash
cd ~/nde

export MUID=$(id -u)
export MGID=$(id -g)

params="$*"
command="docker-compose"

run () {
	$command $params $extra_params
	exit
}

if [[ $params =~ nlog ]]; then params="docker exec -it nde-nginx tail -f /var/log/nginx/*.log"; run; exit; fi

if [[ $params =~ halt ]]; then params=$(echo $params | sed 's/halt/down/'); run; exit; fi

if [[ $params =~ ^up.*-a ]]; then params=$(echo $params | sed 's/ -a//'); run; exit;
else 
	if [[ $params =~ ^up ]]; then if [[ ! $params =~ -d ]]; then extra_params='-d'; run; exit; fi
fi; fi

if [[ $1 == ssh ]] || [[ $1 == '' ]]; then
	command="docker exec -it"
	extra_params="bash"
	if [[ ! -z $2 ]]; then
		if [[ $2 =~ [0-9]+ ]]; then params=$(docker ps --format {{.Names}} | grep $2 | head -n 1)
		else params=$(docker ps --format {{.Names}} | grep nde-$2 | head -n 1); fi
	fi
	if [[ ! $params =~ [\w\d_]+ ]]; then 
		if [[ $2 =~ ^[^\s]+ ]]; then extra_params=$2; fi
		params=nde-php; #$(docker ps --format {{.Names}} | grep nde-php | head -n 1); 
	fi
	if [[ $3 =~ [^\s]+ ]]; then extra_params=$3; fi
	if [[ -z $params ]]; then echo " Container not found."; exit; fi

	run; exit;
fi

if [[ $1 == log ]]; then
	command="docker"
	params="logs -f --details"
	extra_params=nde-php; #$(docker ps --format {{.Names}} | grep nde-php | head -n 1); 

	if [[ ! -z $2 ]]; then
		if [[ $2 =~ [0-9]+ ]]; then extra_params=$(docker ps --format {{.Names}} | grep $2 | head -n 1)
		else extra_params=$(docker ps --format {{.Names}} | grep nde-$2 | head -n 1); fi
	fi
	if [[ -z $extra_params ]]; then echo " Container not found."; exit; fi

 	run; exit;
fi

if [[ $1 == df ]]; then
	docker system df
	exit
fi

if [[ $1 == -kill ]]; then
	params=$(docker ps -q)
	if [[ $params =~ [\w\d]+ ]]; then docker kill $params
	else echo "   No containers to kill"
	fi
	exit;
fi

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


command="docker exec -it"
extra_params="bash"
if [[ ! -z $1 ]]; then
	if [[ $1 =~ [0-9]+ ]]; then params=$(docker ps --format {{.Names}} | grep $1 | head -n 1)
	else params=$(docker ps --format {{.Names}} | grep nde-$1 | head -n 1); fi
fi
if [[ ! $params =~ [\w\d_]+ ]]; then 
	if [[ $1 =~ ^[^\s]+ ]]; then extra_params=$1; fi
	params=nde-php; #$(docker ps --format {{.Names}} | grep nde-php | head -n 1); 
fi
if [[ $2 =~ [^\s]+ ]]; then extra_params=$2; fi
if [[ -z $params ]]; then echo " Container not found."; exit; fi

run; exit;