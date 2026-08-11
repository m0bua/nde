<?php

$file = 'latest-mysql-en.php';

error_reporting(0);
ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
ini_set('memory_limit', '10G');
ini_set('post_max_size', '10G');
ini_set('upload_max_filesize', '10G');
ini_set('max_execution_time', 360);

define('Adminer\\SERVER', $_ENV['ADMINER_DEFAULT_SERVER'] ?? '');

if (!filesize($file)) update($file);
else {
  preg_match('#^\* \@version ([\d\.]+)$#m', file_get_contents($file), $matches);
  if (!empty($matches[1]) && version_compare($matches[1], $_COOKIE['adminer_version'], '<')) {
    echo "<span style=color:red>Updating: {$matches[1]}->{$_COOKIE['adminer_version']}</span>";
    update($file, $_COOKIE['adminer_version']);
  }
}

if ((bool)filesize($file)) {
  ob_start();
  register_shutdown_function(function () {
    $html = ob_get_clean();
    if (empty($_GET['file'])) {
      preg_match('~<script\s+nonce="([^"]+)"~i', $html, $matches);
      $nonce = $matches[1] ?? '';
      $nonceAttribute = $nonce ? ' nonce="'
        . htmlspecialchars($nonce, ENT_QUOTES) . '"' : '';
      $username = env('USER');
      $password = env('PASSWORD');
      $script = <<<HTML
<script$nonceAttribute>
window.addEventListener('load', function () {
  const params = new URLSearchParams(window.location.search)
  if(!params.get('username')) {
    ff('username', $username);
    ff('password', $password);
  }
});
function f(key) {
    return document.querySelector('input[name="auth['+key+']"]');
}
function ff(key, val) {
    const field = f(key);
    if (field && !field.value) field.value = val;
}
</script>
HTML;
      $html .= $script;
    }

    echo $html;
  });

  require_once $file;
} else echo 'Adminer file error!';

function update($file, $ver = null)
{
  $url = empty($ver) ? "https://adminer.org/$file" :
    "https://github.com/vrana/adminer/releases/download/v$ver/"
    . str_replace('latest', "adminer-$ver", $file);
  $data = file_get_contents($url);
  if (!empty($data)) file_put_contents($file, $data);
}

function env(string $key)
{
  $key = strtoupper($key);

  return json_encode(
    $_ENV["ADMINER_DEFAULT_$key"] ?? '',
    JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT
  );
}
