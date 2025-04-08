<?php

$file = 'latest-mysql-en.php';

error_reporting(0);
ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
ini_set('memory_limit', '10G');
ini_set('post_max_size', '10G');
ini_set('upload_max_filesize', '10G');
ini_set('max_execution_time', 360);

if (!filesize($file)) {
  update($file);
} else {
  preg_match('#^\* \@version ([\d\.]+)$#m', file_get_contents($file), $matches);
  if (!empty($matches[1]) && version_compare($matches[1], $_COOKIE['adminer_version'], '<')) {
    echo "<span style=color:red>Updating: {$matches[1]}->{$_COOKIE['adminer_version']}</span>";
    update($file, $_COOKIE['adminer_version']);
  }
}

if ((bool)filesize($file)) require_once $file;
else echo 'Adminer file error!';

function update($file, $ver = null)
{
  $url = empty($ver) ? "https://adminer.org/$file" :
    "https://github.com/vrana/adminer/releases/download/v$ver/"
    . str_replace('latest', "adminer-$ver", $file);
  $data = file_get_contents($url);
  if (!empty($data)) file_put_contents($file, strtr($data, [
    'value="\'.h(SERVER).\'"' =>
    'value="\'.h($_GET["server"]??$_ENV["ADMINER_DEFAULT_SERVER"]??"localhost").\'"',

    'value="\'.h($_GET["username"]).\'"' =>
    'value="\'.h($_GET["username"]??(empty($_GET["server"])'
      . ' ? ($_ENV["ADMINER_DEFAULT_USER"]??""):"")).\'"',

    'auth[password]"' => 'auth[password]"'
      . '\'.(empty($_GET["server"]) && empty($_GET["username"])'
      . '? \' value="\' . h($_ENV["ADMINER_DEFAULT_PASSWORD"] ?? "") . \'"\' : ""). \'',

    "type='image'" => "type='button'",
    "alt='+'" => "value='+'",
    "alt='↑'" => "value='🡅'",
    "alt='↓'" => "value='🡇'",
    "alt='x'" => "value='❌'",
  ]));
}
