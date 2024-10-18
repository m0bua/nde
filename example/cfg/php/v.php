<?php

### Configs ###

$prjName = 'nde';
$prjFolder = '/var/www';
$prjFoldersIgnore = ['.', '..', 'html'];
$redisAddress = 'redis';
$redisPort = 6379;
$xdebugOn = 'debug,develop';
$xdebugOff = 'develop';

### Code ###

if (($_POST['cache'] ?? null) == 'clear') {
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

$dirs = array_filter(
    scandir($prjFolder),
    function ($i) use ($prjFolder, $prjFoldersIgnore) {
        return is_dir("$prjFolder/$i") &&
            !in_array($i, $prjFoldersIgnore);
    }
);

$ch = curl_init('http:/localhost/containers/json');
curl_setopt($ch, CURLOPT_UNIX_SOCKET_PATH, '/var/run/docker.sock');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$conData = json_decode(curl_exec($ch), true) ?? [];
curl_close($ch);
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

if (function_exists('xdebug_info')) {
    $xModes = ['develop', 'debug', 'coverage', 'trace', 'gcstats', 'profile'];
    $xDebs = empty(xdebug_info('mode')) ? ['off'] : xdebug_info('mode');
}

foreach ([INFO_GENERAL, INFO_CONFIGURATION, INFO_VARIABLES, INFO_ENVIRONMENT, INFO_MODULES] as $block) {
    ob_start();
    phpinfo($block);
    [$_, $body] = explode('<div class="center">', ob_get_contents());
    $body = preg_replace('/([^,>]{30,},)\s/', '$1<br>', $body);
    $body = preg_replace('/,([^,])/', ', $1', $body);
    [$phpInfos[]] = explode('</div></body>', $body);
    ob_get_clean();
}
$body = implode("\n", $phpInfos);
?>
<!DOCTYPE html>
<html>

<head>
    <title>NDE <?= strtoupper($ver) ?> <?= phpversion() ?></title>
</head>

<body>

    <div id="header">
        <div>
            <a href="//adminer.<?= $suffix ?>/" style="font-weight:900">adminer</a>
            <a href="//mail.<?= $suffix ?>/" style="font-weight:900">mail</a>
            <?php foreach ($dirs as $dir): ?>
                <a href="//<?= "$dir$host" ?>"><?= $dir ?></a>
            <?php endforeach ?>
        </div>
        <div class="right">
            <?php if (!empty($conteiners) && count($conteiners) > 1): ?>
                <select id="containers">
                    <?php foreach ($conteiners as $conteiner): ?>
                        <option value="<?= $conteiner ?>" <?php if ($ver === $conteiner):
                              ?> selected="selected" <?php endif ?>>
                            <?= $conteiner ?>
                        </option>
                    <?php endforeach ?>
                </select>
            <?php endif ?>
            <?php if (!empty($xModes)): ?>
                <div id="xBlk">
                    <button id="xdebug">Xdebug</button>
                    <div id="xModes" class="hide">
                        <?php foreach ($xModes as $mode): ?>
                            <label>
                                <input type="checkbox" name="xMode[]" value="<?= $mode ?>" <?php
                                  if (in_array($mode, $xDebs)): ?>checked<?php endif ?>>
                                <?= $mode ?>
                            </label>
                        <?php endforeach ?>
                    </div>
                </div>
            <?php endif ?>
            <?php if (in_array($redisAddress, $conList)): ?>
                <button id="redis">Redis cls</button>
            <?php endif ?>
            <button id="toggle">Show all</button>
        </div>
    </div>
    <div class="center">
        <?= $body ?>
    </div>
    <style>
        body {
            background-color: #222;
        }

        #header {
            display: inline-block;
            font-size: 24px;
            line-height: 1.5;
            display: flex;
            justify-content: space-between;
        }

        .right {
            text-align: center;
            position: relative;
        }

        .right>form,
        .right>select,
        .right button {
            display: inline-block;
        }

        .right>select,
        .right button {
            color: #ccc;
            background-color: #000;
            line-height: 1;
            font-size: 18px;
            padding: .5em .7em;
            border-color: #777;
            border-radius: .3em;
        }

        .right>select {
            padding: .4em .7em;
        }

        .right>* {
            margin: .1em 0 .1em 1em;
            text-align: center;
        }

        .right>form {
            margin-left: .7em;
        }

        .right>#xBlk {
            display: inline-block;
            position: relative;
        }

        .right>#xBlk>#xModes {
            position: absolute;
            background-color: #333e;
            padding: .5em;
            border-radius: .3em;
            z-index: 10;
            right: 0;
            top: 100%;
            top: calc(100% + 1em);
        }

        .right>#xBlk>#xModes>label {
            display: block;
            padding: .3em;
            display: flex;
            justify-content: left;
            align-items: left;
            word-wrap: none;
        }

        .right>#xBlk>#xModes>label>input {
            margin-right: 1em;
        }

        #toggle {
            display: button;
        }

        a,
        div.center a:link,
        div.center a:visited,
        div.center h2>a:link,
        div.center h2>a:visited {
            color: #7a0;
            background-color: transparent;
            text-decoration: none;
        }

        a+a {
            margin-left: 1em;
        }

        div.center table,
        div.center h1,
        div.center h2,
        div.center h3 {
            color: #ccc;
        }

        div.center .h,
        div.center .e {
            background-color: #000;
        }

        div.center table:first-child td {
            padding: 1em 12em 1em 3em;
            position: relative;
        }

        div.center table:first-child td img {
            position: absolute;
            top: 1.5em;
            right: 3em;
        }

        div.center th,
        div.center td {
            padding: .5em;
            position: relative;
        }

        div.center td[style],
        div.center .v,
        div.center .d {
            background-color: #111 !important;
        }

        div.center table:not(:first-child) td img {
            display: block;
        }

        #header,
        div.center {
            text-align: left;
            max-width: 1200px;
            margin: .5em auto;
        }

        div.center>h1 {
            display: none;
            text-align: center;
            margin-top: 2em;
        }

        div.center>table {
            width: 100%;
            margin: 1em 0 !important;
        }

        div.center>hr,
        div.center>table:not(:first-child) {
            display: none;
        }

        div.center>h2 {
            color: #999;
            font-size: 18px;
            display: inline-block;
            padding: .5em;
            cursor: pointer;
            margin: .3em .5em;
        }

        div.center>table.show,
        div.center>table.no_hide {
            display: table;
        }

        div.center>h1.show,
        div.center>h2.show {
            display: block;
        }

        div.center>h2.open {
            border: 1.5px solid;
            border-radius: .3em;
        }

        .hide {
            display: none !important;
        }
    </style>
    <script>

        let shownBlocks = getCookies('shown_blocks'),
            containers = document.querySelector('#containers'),
            xdebug = document.querySelector('#xdebug'),
            xdebugInput = document.querySelectorAll('#xModes input'),
            redis = document.querySelector('#redis'),
            toggle = document.querySelector('#toggle'),
            clickEls = document.querySelectorAll('.center > table:first-child, .center > h2');

        shownBlocks = shownBlocks.length ? shownBlocks.split('||') : [];

        if (containers) containers.addEventListener('change', (event) => {
            dom = document.domain.split('.');
            dom[dom.length - 2] = event.target.value;
            window.location.href = window.location.href.replace(document.domain, dom.join('.'));
        });

        if (shownBlocks.filter((value) => value == xdebug.innerText).length) {
            document.querySelector('#xModes').classList.remove('hide');
        }

        if (xdebug) xdebug.addEventListener('click', (event) => {
            el = document.querySelector('#xModes');
            if (el.classList.value.includes('hide')) {
                shownBlkList(event.target.innerText, true);
                el.classList.remove('hide');
            } else {
                shownBlkList(event.target.innerText, false);
                el.classList.add('hide');
            }
        });

        if (xdebugInput) xdebugInput.forEach((el) => el.addEventListener('click', (event) => {
            modes = Array.from(document.querySelectorAll('#xModes input:checked'), node => node.value);
            setCookie('xdebug_mode', modes.length > 0 ? modes.join(',') : 'off');
            window.location.href = window.location.href;
        }));

        if (redis) redis.addEventListener('click', (event) => {
            if (confirm('Are you sure clearing all cache?')) {
                formData = new FormData;
                formData.append('cache', 'clear');
                fetch(window.location.href, { method: "POST", body: formData })
                    .then((res) => res.json())
                    .then((json) => alert(json.result == 'ok' ? 'Done' : 'Error!'));
            }
        });

        if (clickEls) clickEls.forEach((el) => {
            el.addEventListener('click', (event) => toggleBlk(event.target));
            if (shownBlocks.filter((v) => v == el.innerText).length) toggleBlk(el, 'show');
        });

        if (toggle) toggle.addEventListener('click', (event) => {
            let status = event.target.innerText == 'Show all';
            clickEls.forEach((el) => toggleBlk(el, status ? 'show' : 'hide'));
        });

        document.querySelectorAll('.center > h2 > a').forEach((el) => el.removeAttribute("href"));

        function toggleBlk(el, status = '') {
            while (!el.parentElement.classList.contains('center')) el = el.parentElement;
            if (status.length == 0) status = el.classList.contains('open') ? 'hide' : 'show';
            if (status == 'hide') {
                shownBlkList(el.innerText, false);
                el.classList.remove('open');
            } else {
                shownBlkList(el.innerText, true);
                el.classList.add('open');
            }
            while (el.nextElementSibling && el.nextElementSibling.tagName == 'TABLE') {
                el = el.nextElementSibling;
                if (status.length == 0) status = el.classList.contains('show') ? 'hide' : 'show';
                el.classList.remove(status == 'show' ? 'hide' : 'show');
                el.classList.add(status);
                if (status == 'show') document.querySelector('#toggle').innerText = 'Hide all';
                else if (!document.querySelectorAll('.center > table:not(:first-child).show').length)
                    document.querySelector('#toggle').innerText = 'Show all';
            }
        }

        function shownBlkList(name, status) {
            blks = getCookies('shown_blocks');
            blks = blks.length ? blks.split('||') : [];

            if (status) blks.push(name);
            else blks = blks.filter((value) => value != name);

            blks = blks.filter((value, index, array) =>
                array.indexOf(value) == index).sort();

            setCookie('shown_blocks', blks.join('||'));
        }

        function getCookies(key = null, def = '') {
            let cookies = {};
            document.cookie.split('; ').forEach(($i) => {
                cookies[$i.split('=')[0]] = $i.split('=')[1];
            });

            return key ? cookies[key] ?? def : cookies ?? def;
        }

        function setCookie(key, val) {
            dom = document.domain.split('.');
            dom[0] = '';

            document.cookie = key + '=' + val
                + '; domain=' + dom.join('.')
                + '; SameSite=lax';
        }
    </script>

</body>

</html>
