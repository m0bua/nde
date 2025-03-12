<?php

$file = 'latest-mysql-en.php';

error_reporting(0);
ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
ini_set('memory_limit', '10G');
ini_set('post_max_size', '10G');
ini_set('upload_max_filesize', '10G');
ini_set('max_execution_time', 360);

if (!filesize($file)) update($file);
else {
  preg_match('/\$ga="([^"]+)"/', file_get_contents($file), $matches);
  if (version_compare($_COOKIE['adminer_version'], $matches[1] ?? 0))
    update($file);
}

if ((bool)filesize($file)) require_once $file;
else echo 'Adminer file error!';

function update($file)
{
  file_put_contents($file, strtr(file_get_contents("https://adminer.org/$file"), [
    'value="\'.h(SERVER).\'"' =>
    'value="\'.h($_GET["server"]??$_ENV["ADMINER_DEFAULT_SERVER"]??"localhost").\'"',

    'value="\'.h($_GET["username"]).\'"' =>
    'value="\'.h($_GET["username"]??$_ENV["ADMINER_DEFAULT_USER"]??"").\'"',

    'auth[password]"' => 'auth[password]" value="\'.h(empty($_GET["table"])'
      . '?($_ENV["ADMINER_DEFAULT_PASSWORD"]??""):"").\'"',

      "type='image'" => "type='button'",
      "alt='+'" => "value='+'",
      "alt='↑'" => "value='🡅'",
      "alt='↓'" => "value='🡇'",
      "alt='x'" => "value='❌'",
  ]));
}
