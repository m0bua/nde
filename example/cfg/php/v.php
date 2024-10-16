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

if (($_POST['cache'] ?? false) == 'clear') {
    $redis = new Redis;
    $redis->connect($redisAddress, $redisPort);
    $redis->flushall();
    header('Location: ' . $_SERVER['HTTP_HOST']);
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

$xDeb = function_exists('xdebug_info') && !empty(xdebug_info('mode'))
    ? implode(',', xdebug_info('mode')) : 'off';

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
$conList = array_map(function ($i) {
    return $i['Labels']['com.docker.compose.service'];
}, $conData);

sort($conteiners);

foreach (
    [
        INFO_GENERAL,
        INFO_CONFIGURATION,
        INFO_VARIABLES,
        INFO_ENVIRONMENT,
        INFO_MODULES
    ] as $block
) {
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
            <?php if (!empty($conteiners)): ?>
                <select>
                    <?php foreach ($conteiners as $conteiner): ?>
                        <option value="<?= $conteiner ?>" <?php if ($ver === $conteiner):
                                                            ?> selected="selected" <?php endif ?>>
                            <?= $conteiner ?>
                        </option>
                    <?php endforeach ?>
                </select>
            <?php endif ?>
            <button id="xdebug">XDebug: <?= $xDeb ?></button>
            <?php if (in_array($redisAddress, $conList)): ?>
                <form method="post">
                    <input type="hidden" name="cache" value="clear">
                    <button>Redis cls</button>
                </form>
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

        div.center>table.hide,
        div.center>h1.hide,
        div.center>h2.hide {
            display: none;
        }

        div.center>h1.show,
        div.center>h2.show {
            display: block;
        }

        div.center>h2.open {
            border: 1.5px solid;
            border-radius: .3em;
        }
    </style>
    <script>
        let clickEls = '.center > table:first-child, .center > h2';

        document.querySelectorAll('.center > h2 > a').forEach((el) => {
            el.removeAttribute("href");
        });

        document.querySelectorAll(clickEls).forEach((el) => {
            el.addEventListener('click', (event) => toggle(event.target));
        });

        document.querySelector('#toggle').addEventListener('click', (event) => {
            let status = event.target.innerHTML == 'Show all';
            document.querySelectorAll(clickEls).forEach((el) => {
                toggle(el, status ? 'show' : 'hide');
            });
        });

        document.querySelector('#header>.right>select').addEventListener('change', (event) => {
            let href = window.location.href.split('.');
            href[href.length - 2] = event.target.value;
            window.location.href = href.join('.');
        });

        document.querySelector('#xdebug').addEventListener('click', (event) => {
            let domain = window.location.hostname.split('.');
            domain[0] = '';

            document.cookie = 'xdebug_mode=' +
                (cookies().xdebug_mode == '<?= $xdebugOff ?>' ?
                    '<?= $xdebugOn ?>' : '<?= $xdebugOff ?>') +
                '; domain=' + domain.join('.') + '; SameSite=Lax'
            window.location.href = window.location.href;
        });

        function toggle(el, status = '') {
            while (!el.parentElement.classList.contains('center')) el = el.parentElement;

            if (status.length == 0) status = el.classList.contains('open') ? 'hide' : 'show';

            if (status == 'hide') el.classList.remove('open');
            else el.classList.add('open');

            while (el.nextElementSibling && el.nextElementSibling.tagName == 'TABLE') {
                el = el.nextElementSibling;
                if (status.length == 0)
                    status = el.classList.contains('show') ? 'hide' : 'show';

                el.classList.remove(status == 'show' ? 'hide' : 'show');
                el.classList.add(status);

                if (status == 'show')
                    document.querySelector('#toggle').innerHTML = 'Hide all';
                else if (!document.querySelectorAll('.center > table:not(:first-child).show').length) {
                    document.querySelector('#toggle').innerHTML = 'Show all';
                }
            }
        }

        function cookies(key = null) {
            let cookies = {};
            document.cookie.split('; ').forEach(($i) => {
                cookies[$i.split('=')[0]] = $i.split('=')[1];
            });

            return cookies[key] ?? cookies;
        }
    </script>

</body>

</html>
