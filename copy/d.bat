@ECHO OFF
setlocal ENABLEDELAYEDEXPANSION

set command=docker-compose
set params=%*
set extra_params=

set MUID=1000
set MGID=1000

if [%1]==[] (
	set command=docker exec -it
	set params=nde-php
	set extra_params=bash

	goto command
)

if %1==up (
	if not "x%params:-a=%"=="x%params%" set params=%params:-a=%
	if "x%params:-a=%"=="x%params%" set params=%params% -d
	goto command
)

if %1==nlog (
	set command=docker
	set params=exec nde-nginx tail -f /var/log/nginx/*.log
	
	goto command
)

if %1==halt (
	set params=%params:halt=down%
	
	goto command
)

if %1==df (
	set command=docker
	set params=system df
	
	goto command
)

if %1==ssh (
	set command=docker exec -it
	set params=nde-php
	set extra_params=bash

	if not [%2]==[]	goto param2
	if not [%2]==[]	goto param2

	goto command
)

if %1=='' (
	set command=docker exec -it
	set params=nde-php
	set extra_params=bash

	if not [%2]==[]	goto param2

	goto command
)

if %1==log (
	set command=docker logs -f --details
	set params=nde-php

	if not [%2]==[]	goto param2

	goto command
)


if %1==-kill (
	for /F %%p in ('docker ps -q') do docker kill %%p

	GOTO:EOF
)

if %1==-purge (
	echo  Killing all running containers:
	for /F %%p in ('docker ps -q') do docker kill %%p
	echo  Removing all containers:
	for /F %%p in ('docker ps -aq') do docker rm %%p
	echo  Removing all images:
	for /F %%p in ('docker images -q') do docker rmi --force %%p
	
	GOTO:EOF
)


:command
set OLDDIR=%CD%
chdir /d %userprofile%\nde
%command% %params% %extra_params%
chdir /d %OLDDIR%
GOTO:EOF


:param2
set temp_param=%2
if %temp_param:nde-=%==%temp_param% set extra_params=%temp_param%
if not %temp_param:nde-=%==%temp_param% set params=%temp_param%
if not [%3] == [] (
	set params=%2
	set extra_params=%3
)
goto command
