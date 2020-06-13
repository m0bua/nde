$default_container='php73'

$dir = Split-Path -parent $PSScriptRoot;

function run($exit=$true) {
  Invoke-Expression "$command $params $extra_params"
  if($exit){exit}
}

try {
  Push-Location
  Set-Location -Path  $dir

  $command="docker-compose"
  $params="$args"
  $extra_params=""

  if ($params -eq '-init') {./init.ps1 script; exit}

  if ($params -eq '-purge') {
    $command='docker'
    echo " Killing all running containers:"
    $extra_params=$(docker ps -q)
    if ($extra_params -match '[\w\d]+' ){
      $params="kill"; run($false)
    } else { echo "   No containers to kill." }
    echo " Removing all containers:"
    $extra_params=$(docker ps -aq)
    if ($extra_params -match '[\w\d]+' ){
      $params="rm"; run($false)
    } else { echo "   No containers to remove." }
    echo " Removing all images:"
    $extra_params=$(docker images -q)
    if ($extra_params -match '[\w\d]+' ){
      $params="rmi --force"; run($false)
    } else { echo "   No images to remove." }
    exit
  }

  if ($params -eq '-delete') {
    $command='docker'
    echo " Killing all running containers:"
    $extra_params=$(docker ps -q)
    if ($extra_params -match '[\w\d]+' ){
      $params="kill"; run($false)
    } else { echo "   No containers to kill." }
    echo " Removing all containers:"
    $extra_params=$(docker ps -aq)
    if ($extra_params -match '[\w\d]+' ){
      $params="rm"; run($false)
    } else { echo "   No containers to remove." }
    exit
  }

  if ( $params -eq '-kill') {
    if ( $(docker ps -q) -match '[\w\d]+' ){$command='docker';$params="kill $(docker ps -q)"}
    else {echo "   No containers to kill";exit}
  }

  if (!$args[0]){
    $params = $(docker ps --format '{{.Names}}' | select-string "^nde-.*$default_container" | select -first 1)
  } else {
    $cont = $args[0]
    $params = "$(docker ps --format '{{.Names}}' | select-string "^nde-.*$cont" | select -first 1)"
  }

  if ($params){ 
    $command="docker exec -it";$extra_params="bash"
    if ( $args[1] -match '[^\s]+' ){$extra_params=$args[1]}
  } elseif (!"$(docker ps --format '{{.Names}}')" -and !$args[0]) {
    $params="up"; $extra_params="-d"
  } else {
    $params="$args"
  }

  if ( $params -eq 'df' ){ $command='docker'; $params='system df' }
  if ( $params -match 'halt' ){$params=($params -replace "halt", "down")}
  if ( $params -match '^up.*-a'){$params=($params -replace "-a", "")}
  elseif ($params -match '^up' -and (!($params -match '-d'))) {$extra_params='-d'}

  run($true)

} finally { Pop-Location }