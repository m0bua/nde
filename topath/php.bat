@echo off
set str=%*
set str=%str:*\prj=/var/www%
set str=%str:\=/%
docker exec -it php php %str%
