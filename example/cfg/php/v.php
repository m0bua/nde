<?php
$host = explode('.', $_SERVER['HTTP_HOST']);
$host[0] = '';
$host = implode('.', $host);

if (isset($_POST['mode'])) {
    setcookie('mode', $_POST['mode'], ['domain' => $host]);
    header("Location: /");
}

ob_start();
phpinfo();
[$head, $body] = explode('<body>', ob_get_contents());
[$body] = explode('</body>', $body);
ob_get_clean();

echo $head;

$path = '/var/www';
$isOn = in_array(strtolower($_POST['mode'] ?? $_COOKIE['mode'] ?? ''), ['x', 'xdebug']);
?>

<body>
    <div id="header">
        <a target="_blank" href="//adminer.d/">adminer</a>
        <a target="_blank" href="//mail.d/">mail</a>
        <?php foreach (scandir($path) as $dir): ?>
            <?php if (is_dir("$path/$dir") && !in_array($dir, ['.', '..', 'html'])): ?>
                <a target="_blank" href="//<?= "$dir$host" ?>">
                    <?= $dir ?>
                </a>
            <?php endif ?>
        <?php endforeach ?>

        <div class="right">
            <form method="post">
                <input type="hidden" name="mode" value="<?= $isOn ? '' : 'xdebug' ?>">
                <button id="mode">
                    XDebug: <?= $isOn ? 'On' : 'Off' ?>
                </button>
            </form>
            <button id="toggle">Show all</button>
        </div>
    </div>

    <?= $body ?>

    <style>
        body {
            background-color: #000;
        }

        #header {
            display: block;
            position: relative;
            font-size: 24px;
        }

        .right {
            position: absolute;
            top: 0;
            right: 0;
        }

        .right form {
            display: inline;
        }

        .right button {
            padding: .3em .7em
        }

        #toggle {
            display: button;
        }

        a,
        a:link {
            color: #7a0;
            background-color: transparent;

        }

        a+a {
            margin-left: 1em;
        }

        table,
        h1,
        h2,
        h3 {
            color: #ccc;
        }

        .h,
        .e {
            background-color: #111;
        }

        td[style],
        .v {
            background-color: #333 !important;
        }

        #header,
        div.center {
            text-align: left;
            max-width: 1200px;
            margin: 1.5em auto;
        }

        div.center>h1 {
            display: block;
            text-align: center;
        }

        div.center>table {
            width: 100%;
            margin: 1em 0 !important;
        }

        div.center>hr,
        div.center>table:not(:first-child) {
            display: none;
        }

        div.center>h1 {
            margin-top: 2em;
        }

        div.center>h2 {
            color: #999;
            font-size: 100%;
            display: inline-block;
            padding: .1em .2em;
            cursor: pointer;
        }

        div.center>h2.open {
            display: block;
            text-align: center;
        }

        div.center>h2.open a {
            color: #fff;
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
    </style>
    <script>
        document.querySelectorAll('.center > table:first-child, .center > h2:not(.no_hide)').forEach((el) => {
            el.addEventListener('click', (event) => toggle(event.target));
        });

        document.querySelectorAll('.center > h1').forEach((el) => {
            if (el.nextElementSibling.tagName == 'TABLE')
                do {
                    if (el.tagName == 'H2') {
                        el.removeEventListener('click', (event) => toggle(event.target));
                        el.classList.add('open');
                    }
                    el.classList.add('hide');
                    el.classList.add('no_hide');
                    el = el.nextElementSibling;
                } while (el)
        });

        document.querySelector('#toggle').addEventListener('click', (event) => {
            let status = event.target.innerHTML == 'Show all';

            document.querySelectorAll('.center > table:first-child, .center > h2:not(.no_hide)').forEach((el) => {
                toggle(el, status ? 'show' : 'hide');
            });
            document.querySelectorAll('.center > .no_hide').forEach((el) => {
                toggleTbl(el, status ? 'show' : 'hide');
            });


        });

        function toggle(el, status = '') {
            {
                while (!el.parentElement.classList.contains('center'))
                    el = el.parentElement;

                if (status.length == 0)
                    status = el.classList.contains('open') ? 'hide' : 'show';

                if (status == 'hide') el.classList.remove('open');
                else el.classList.add('open');

                while (el.nextElementSibling &&
                    el.nextElementSibling.tagName == 'TABLE') {
                    el = el.nextElementSibling;
                    toggleTbl(el, status);
                }
            }
        }

        function toggleTbl(el, status = '') {
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
    </script>
</body>

</html>
