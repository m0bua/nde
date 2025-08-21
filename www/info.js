resize();
window.onresize = resize;

function handleclick(event) {
  event.preventDefault()
  window.focus();
}

let shownBlocks = getCookies('shown_blocks'),
  containers = document.querySelector('#containers'),
  xdebug = document.querySelector('#xdebug'),
  xModes = document.querySelector('#xModes'),
  xModesInput = document.querySelectorAll('#xModes input'),
  redis = document.querySelector('#redis'),
  toggle = document.querySelector('#toggle'),
  clickEls = document.querySelectorAll('.center > table:first-child, .center > h2');

shownBlocks = shownBlocks.length ? shownBlocks.split('||') : [];

if (containers) containers.addEventListener('change', (event) => {
  dom = document.location.host.split('.');
  dom[dom.length - 2] = event.target.value;
  window.location.href = window.location.href.replace(document.location.host, dom.join('.'));
});

if (xdebug && xModes) {
  if (shownBlocks.filter((v) => v == 'xdebugSelect').length)
    xModes.classList.remove('hide');

  document.addEventListener('click', (event) => {
    let target = event.target;
    while (target)
      if (target == xModes) break;
      else target = target.parentElement;

    if (xModes.classList.value.includes('hide') &&
      event.target == xdebug) {
      shownBlkList('xdebugSelect', true);
      xModes.classList.remove('hide');
    } else if (target != xModes) {
      shownBlkList('xdebugSelect', false);
      xModes.classList.add('hide');
    }
  });

  xdebug.addEventListener('click', (event) => {
    event.preventDefault()
    event.target.focus();
  });

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
      shownBlkList(xdebug.innerText, false);
      if (xModes) xModes.classList.add('hide');
    }
  });

  if (xModesInput) xModesInput.forEach((el) => el.addEventListener('change', (event) => {
    setXdebugCookie(event.target.name, event.target.type = 'checkbox');
    window.location.href = window.location.href;

    if (getCookies('php_val').length == 0)
      setXdebugCookie(xModesInput[0].name);
  }));
}

if (redis) redis.addEventListener('click', () => {
  if (confirm('Are you sure clearing all cache?')) {
    formData = new FormData;
    formData.append('cache', 'clear');
    fetch(window.location.href, {
      method: "POST",
      body: formData
    })
      .then((res) => res.json())
      .then((json) => alert(json.result == 'ok' ? 'Done' : 'Error!'));
  }
});

if (clickEls) clickEls.forEach((el) => {
  el.addEventListener('click', (event) => toggleBlk(event.target));
  if (shownBlocks.filter((v) => v == el.innerText).length) toggleBlk(el, 'show');
});

if (toggle) toggle.addEventListener('click', (event) => {
  let status = toggle.innerText == 'Show';
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
  el = el.nextElementSibling;
  if (status.length == 0) status = el.classList.contains('show') ? 'hide' : 'show';
  el.classList.remove(status == 'show' ? 'hide' : 'show');
  el.classList.add(status);
  if (status == 'show') toggle.innerText = 'Hide';
  else if (!document.querySelectorAll('.center > table:not(:first-child).show').length)
    toggle.innerText = 'Show';
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

function setXdebugCookie(n, selected = true) {
  let val;

  selector = '#xModes [name="' + n + '"]';
  if (selected) selector += ':checked';
  document.querySelectorAll(selector).forEach((el) => {
    if (el.name.includes('[]')) {
      if (val == undefined) val = [];
      val.push(el.value);
    } else {
      val = el.value;
    }
  });

  n = n.replace('[]', '');

  if (val == undefined) {
    el = document.querySelector('#xModes [name="' + n + '"][type=hidden]');
    if (el != undefined) val = el.value;
  }

  if (Array.isArray(val)) val = val.join(',');

  if (val != undefined)
    setCookie('php_val', n + '=' + val, 3600 * 24 * 365);
}

function getCookies(key = null, def = '') {
  let cookies = {};
  document.cookie.split('; ').forEach((i) => {
    n = i.split('=')[0];
    cookies[n] = i.replace(n + '=', '');
  });

  return key ? cookies[key] ?? def : cookies ?? def;
}

function setCookie(key, val = null, age = 0, site = 'lax') {
  dom = document.domain.split('.');
  dom[0] = '';

  cookie = key + '=' + val +
    '; domain=' + dom.join('.') +
    '; SameSite=' + site;

  if (age != 0) cookie += '; max-age=' + age;

  document.cookie = cookie
}

function resize() {
  blk = document.querySelector('#header .right');
  blk.style.width = blk.style.minWidth = 'auto';
  els = document.querySelectorAll('#header .right > *');
  widths = Array.prototype.map.call(els, (val) => val.offsetWidth);
  fitNum = propCont(blk.offsetWidth / Math.max(...widths), widths);
  maxChunk = 0;
  for (let i = 0; i < widths.length; i += fitNum) {
    sum = widths.slice(i, i + fitNum).reduce((acc, a) => acc + a, 0)
    if (sum > maxChunk) maxChunk = sum;
  }

  blk.style.width = blk.style.minWidth =
    (maxChunk + (8 * fitNum) + 10) + 'px';
}

function propCont(fitNum, widths) {
  fitNum = Math.floor(fitNum);
  prop = widths.length / fitNum;
  if (prop > 1 && prop != Math.ceil(prop))
    fitNum = propCont(fitNum - 1, widths);

  return fitNum;
}
