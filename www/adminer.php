<?php

$file = __DIR__ . '/latest-mysql-en.php';

error_reporting(0);
ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
ini_set('memory_limit', '10G');
ini_set('post_max_size', '10G');
ini_set('upload_max_filesize', '10G');
ini_set('max_execution_time', 360);

if (!is_file($file) || filesize($file) === 0) update($file);
else {
  preg_match('#^\* \@version ([\d\.]+)$#m', file_get_contents($file), $matches);
  $version = $_COOKIE['adminer_version'] ?? '';

  if (!empty($matches[1])
    && preg_match('/^\d+(?:\.\d+)*$/', $version)
    && version_compare($matches[1], $version, '<')
  ) {
    echo "<span style=color:red>Updating: {$matches[1]}->{$version}</span>";
    update($file, $version);
  }
}

clearstatcache(true, $file);

if (is_file($file) && filesize($file) > 0) {
  ob_start(function (string $html): string {
    if (!empty($_GET['file'])) return $html;

    preg_match('~<script\s+nonce="([^"]+)"~i', $html, $matches);
    $nonce = $matches[1] ?? '';
    $nonceAttribute = $nonce ? ' nonce="'
      . htmlspecialchars($nonce, ENT_QUOTES) . '"' : '';
    $server = env('server');
    $username = env('user');
    $password = env('password');
    $script = <<<HTML
<script$nonceAttribute>
window.addEventListener('load', function () {
  const params = new URLSearchParams(window.location.search)
  fieldFill('server', $server);
  if(!params.get('username')) {
    fieldFill('username', $username);
    fieldFill('password', $password);
  }
});
function fieldFill(key, val) {
    const field = document.querySelector(`input[name="auth[\${key}]"]`);
    if (field && !field.value) field.value = val;
}
</script>
HTML;

    return $html . $script;
  });

  require_once $file;
} else echo 'Adminer file error!';

function update(string $file, ?string $ver = null): bool
{
  if ($ver !== null && !preg_match('/^\d+(?:\.\d+)*$/', $ver)) return false;

  $name = basename($file);
  $url = $ver === null ? "https://adminer.org/$name" :
    "https://github.com/vrana/adminer/releases/download/v$ver/"
    . str_replace('latest', "adminer-$ver", $name);
  $data = @file_get_contents($url);

  if (!$data) return false;

  $temporary = $file . '.tmp';
  if (file_put_contents($temporary, $data, LOCK_EX) === false) return false;
  if (!rename($temporary, $file)) {
    @unlink($temporary);
    return false;
  }

  return true;
}

function env(string $key)
{
  $key = strtoupper($key);

  return json_encode(
    $_ENV["ADMINER_DEFAULT_$key"] ?? '',
    JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT
  );
}
