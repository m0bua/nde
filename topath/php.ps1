$default_container='php'
$params=[System.Text.RegularExpressions.Regex]::Replace("$args", "^.*\\prj\\", "/var/www/").replace("\", '/')
echo $params >> log.txt
docker exec -it $default_container php $params >> log.txt
docker exec -it $default_container php $params
