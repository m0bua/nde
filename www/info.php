<?php

### Configs ###
$prjName = 'nde';
$prjFolder = '/var/www';
$redisAddress = 'redis';
$redisPort = 6379;
$xdebugText = 'Xdbg';
$cacheText = 'Cache';

### Code ###
if (isset($_POST['cache']) && ($_POST['cache']) == 'clear') {
  $redis = new Redis;
  $redis->connect($redisAddress, $redisPort);
  $redis->flushall();
  header('Content-type: application/json');
  echo '{"result":"ok"}';
  exit;
}

$host = explode('.', $_SERVER['HTTP_HOST']);
$ver = $host[count($host) - 2];
$suffix = $host[count($host) - 1];
$host[0] = '';
$host = implode('.', $host);

$dirs = array_filter(scandir($prjFolder), function ($i) use ($prjFolder) {
  return strpos($i, '.') !== 0 && $i !== 'html' && is_dir("$prjFolder/$i");
});

if ($socket = stream_socket_client('unix:///var/run/docker.sock')) {
  fwrite($socket, implode("\n", [
    "GET /containers/json HTTP/1.1",
    "Host:localhost",
    "Connection: Close",
    "",
    "",
  ]));
  $r = stream_get_contents($socket);
  fclose($socket);
  $r = explode("\r\n\r\n", $r);
  if (isset($r[1]))
    $r = explode("\r\n", $r[1]);
  if (isset($r[1])) $containers = $r[1];
} elseif (defined('CURLOPT_UNIX_SOCKET_PATH')) {
  $ch = curl_init('http:/localhost/containers/json');
  curl_setopt($ch, CURLOPT_UNIX_SOCKET_PATH, '/var/run/docker.sock');
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  $containers = curl_exec($ch);
  curl_close($ch);
}
if (!empty($containers)) {
  $conData = json_decode($containers, true);
  $conteiners = array_map(function ($i) {
    return $i['Labels']['com.docker.compose.service'];
  }, array_filter($conData, function ($i) use ($prjName) {
    return $i['Command'] === 'docker-php-entrypoint php-fpm' &&
      $i['Labels']['com.docker.compose.project'] = $prjName;
  }));
  sort($conteiners);
  $conList = array_map(function ($i) {
    return $i['Labels']['com.docker.compose.service'];
  }, $conData);
} else $conList = [];

if (function_exists('xdebug_info')) {
  $xModes = ['develop', 'debug', 'coverage', 'trace', 'gcstats', 'profile'];
  $xDebs = empty(xdebug_info('mode')) ? ['off'] : xdebug_info('mode');
}

libxml_use_internal_errors(true);
foreach ([INFO_GENERAL, INFO_VARIABLES, INFO_ENVIRONMENT, INFO_MODULES] as $block) {
  ob_start();
  phpinfo($block);
  $html = ob_get_contents();
  ob_get_clean();

  $dom = new DOMDocument();
  $dom->loadHTML(mb_encode_numericentity(htmlspecialchars_decode(
    htmlentities($html, ENT_NOQUOTES, 'UTF-8', false),
    ENT_NOQUOTES
  ), [0x80, 0x10FFFF, 0, ~0], 'UTF-8'));
  $div = (new DOMXPath($dom))->query('/html/body/div')->item(0);

  $body = '';
  foreach ($div->childNodes as $node) {
    if (in_array($node->nodeName, ['#text', 'hr', 'h1'])) continue;
    $html = trim($dom->saveHTML($node));
    $isHead = empty($body) || $node->nodeName == 'h2';
    if ($isHead && !empty($body)) $body .= "</span>\n";
    $body .= trim("\n$html");
    if ($isHead) $body .= "<span>\n";
  }
  $phpInfos[] = "$body</span>";
}

$body = implode("\n", $phpInfos);
$body = preg_replace('/([^,>]{30,},)\s/', '$1<br>', $body);
$body = preg_replace('/,([^,])/', ', $1', $body);
?>
<!DOCTYPE html>
<html>

<head>
  <title>NDE <?= strtoupper($ver) ?> <?= phpversion() ?></title>
  <link href="/main.css" rel="stylesheet" type="text/css">
</head>

<body id="infoB">

  <div id="header">
    <div class="left">
      <a href="//adminer<?= $host ?>/" style="font-weight:900">adminer</a>
      <a href="//mail.<?= $suffix ?>/" style="font-weight:900">mail</a>
      <?php foreach ($dirs as $dir): ?>
        <a href="//<?= "$dir$host" ?>"><?= $dir ?></a>
      <?php endforeach ?>
    </div>
    <div class="right">
      <?php if (!empty($xModes)): ?>
        <div id="xBlk">
          <select id="xdebug" onmousedown="handleclick(event)">
            <option selected><?= $xdebugText ?></option>
          </select>
          <div id="xModes" class="hide">
            <?php if (version_compare(phpversion('xdebug'), '3.2.0') >= 0): ?>
              <label>
                <input type="checkbox" name="xdebug.start_with_request" value="on"
                  <?php if (ini_get('xdebug.start_with_request') == '1'): ?>checked<?php endif ?>>
                Status
                <input type="hidden" name="xdebug.start_with_request" value="off">
              </label>
            <?php else: ?>
              <?php foreach ($xModes as $mode): ?>
                <label>
                  <input type="checkbox" name="xdebug.mode[]" value="<?= $mode ?>"
                    <?php if (in_array($mode, $xDebs)): ?>checked<?php endif ?>>
                  <?= $mode ?>
                </label>
              <?php endforeach ?>
              <input type="hidden" name="xdebug.mode" value="off">
            <?php endif ?>
          </div>
        </div>
      <?php endif ?>
      <?php if (!empty($conteiners) && count($conteiners) > 1): ?>
        <select id="containers">
          <?php foreach ($conteiners as $conteiner): ?>
            <option value="<?= $conteiner ?>"
              <?php if ($ver === $conteiner): ?> selected="selected" <?php endif ?>>
              <?= $conteiner ?>
            </option>
          <?php endforeach ?>
        </select>
      <?php endif ?>
      <?php if (in_array($redisAddress, $conList)): ?>
        <button id="redis"><?= $cacheText ?></button>
      <?php endif ?>
      <button id="toggle">Show</button>
    </div>
  </div>
  <div class="center">
    <?= $body ?>
  </div>

  <script src="/main.js"></script>
</body>

</html>
