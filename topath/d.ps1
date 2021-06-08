$default_container='php'


function run($exit=$true) {
  Invoke-Expression "$command $params $extra_params"
  if($exit){exit}
}

$path = Split-Path -parent $PSScriptRoot;
$config = "$path\docker-compose.yml";

$command = "docker-compose -f $config"
$params = "$args"
$extra_params = ""

if ($params -eq '-init') { ./init.ps1 script; exit }

if ($params -eq '-purge') {
  Write-Output " Stopping NDE:"
  $params = "down"; run($false)
  $command = 'docker'
  Write-Output " Killing all running containers:"
  $extra_params = $(docker ps -q)
  if ($extra_params -match '[\w\d]+' ) {
    $params = "kill"; run($false)
  }
  else { Write-Output "   No containers to kill." }
  Write-Output " Removing all containers:"
  $extra_params = $(docker ps -aq)
  if ($extra_params -match '[\w\d]+' ) {
    $params = "rm"; run($false)
  }
  else { Write-Output "   No containers to remove." }
  Write-Output " Removing all images:"
  $extra_params = $(docker images -q)
  if ($extra_params -match '[\w\d]+' ) {
    $params = "rmi --force"; run($false)
  }
  else { Write-Output "   No images to remove." }
  exit
}

if ($params -eq '-delete') {
  Write-Output " Stopping NDE:"
  $params = "down"; run($false)
  $command = 'docker'
  Write-Output " Killing all running containers:"
  $extra_params = $(docker ps -q)
  if ($extra_params -match '[\w\d]+' ) {
    $params = "kill"; run($false)
  }
  else { Write-Output "   No containers to kill." }
  Write-Output " Removing all containers:"
  $extra_params = $(docker ps -aq)
  if ($extra_params -match '[\w\d]+' ) {
    $params = "rm"; run($false)
  }
  else { Write-Output "   No containers to remove." }
  exit
}

if ( $params -eq '-kill') {
  Write-Output " Stopping NDE:"
  $params = "down"; run($false)
  if ( $(docker ps -q) -match '[\w\d]+' )
  { $command = 'docker'; $params = "kill $(docker ps -q)" }
  else { Write-Output "   No containers to kill"; exit }
}

if ($args[0]) { $default_container = $args[0] }
$params = $(docker ps --format '{{.Names}}' | Sort-Object)
$params = $($params | select-string "^.*$default_container" | select -first 1)

if ($params) { 
  $command = "docker exec -it"; $extra_params = "bash"
  if ( $args[1] -match '[^\s]+' ) { $extra_params = $args[1] }
}
elseif (!"$(docker ps --format '{{.Names}}')" -and !$args[0]) {
  $params = "up"; $extra_params = "-d"
}
else {
  $params = "$args"
}

if ( $params -eq 'df' ) { $command = 'docker'; $params = 'system df' }
if ( $params -match 'halt' ) { $params = ($params -replace "halt", "down") }
if ( $params -match '^up.*-a') { $params = ($params -replace "-a", "") }
elseif ($params -match '^up' -and (!($params -match '-d'))) { $extra_params = '-d' }

run($true)
