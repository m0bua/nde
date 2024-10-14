<?php
$host = explode('.', $_SERVER['HTTP_HOST']);
$host[0] = '';
$host = implode('.', $host);

if (isset($_POST['xdebug_mode'])) {
    setcookie('xdebug_mode', $_POST['xdebug_mode'], ['domain' => $host]);
    header("Location: /");
}

$blocks = [
    INFO_GENERAL,
    INFO_CONFIGURATION,
    INFO_VARIABLES,
    INFO_ENVIRONMENT,
    INFO_MODULES
];

foreach ($blocks as $block) {
    ob_start();
    phpinfo($block);
    [$_, $body] = explode('<div class="center">', ob_get_contents());
    $body = preg_replace('/([^,>]{30,},)\s/', '$1<br>', $body);
    $body = preg_replace('/,([^,])/', ', $1', $body);
    [$php[]] = explode('</div></body>', $body);
    ob_get_clean();
}
$body = implode("\n", $php);

$path = '/var/www';
$isOn = strtolower($_POST['xdebug_mode'] ?? $_COOKIE['xdebug_mode'] ?? '') == 'xdebug';
?>
<!DOCTYPE html>
<html>

<body>
    <div id="header">
        <a href="//adminer.d/">adminer</a>
        <a href="//mail.d/">mail</a>
        <?php foreach (scandir($path) as $dir): ?>
            <?php if (is_dir("$path/$dir") && !in_array($dir, ['.', '..', 'html'])): ?>
                <a href="//<?= "$dir$host" ?>"><?= $dir ?></a>
            <?php endif ?>
        <?php endforeach ?>

        <div class="right">
            <form method="post">
                <input type="hidden" name="xdebug_mode" value="<?= $isOn ? '' : 'xdebug' ?>">
                <button>XDebug: <?= $isOn ? 'On' : 'Off' ?></button>
            </form><button id="toggle">Show all</button>
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
            margin-left: 1em;
        }

        .right>form,
        .right>button {
            font-size: 24px;
            display: inline-block;
        }

        .right :not(:first-child) {
            margin-left: 1em;
        }

        .right button {
            font-size: 18px;
            line-height: 1;
            padding: .5em .7em;
            color: #ccc;
            background-color: #000;
            border-color: #777;
            border-radius: .3em;
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
            padding: .51em;
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

        div.center>h2.open{
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
    </script>
</body>

</html>
