#!/usr/bin/env node
// Visual board for brainstorming: a tiny local web page that shows the newest HTML screen
// Claude wrote, refreshes itself when a new one appears, and records the owner's clicks.
//
//   node board.cjs --dir <main checkout>/.plans/brainstorm [--port 0] [--open]
//   node board.cjs --dir <same dir> --stop
//
// Claude writes screens as <dir>/screens/NN-name.html (an HTML fragment or a full document).
// The owner clicks any element carrying data-choice="..." (and may add a note); each pick is
// appended as one JSON line to <dir>/choices.jsonl. Connection info goes to <dir>/board.json.
// Listens on 127.0.0.1 only; every request needs the random token from the URL.
// No dependencies. Exits by itself after 2 hours without a request.

'use strict';
const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { spawn } = require('child_process');

const args = process.argv.slice(2);
const opt = (name, fallback) => {
  const i = args.indexOf(name);
  return i >= 0 && args[i + 1] && !args[i + 1].startsWith('--') ? args[i + 1] : fallback;
};
const flag = (name) => args.includes(name);

const dir = path.resolve(opt('--dir', path.join(process.cwd(), ".plans", "brainstorm")));
const screensDir = path.join(dir, 'screens');
const choicesFile = path.join(dir, 'choices.jsonl');
const infoFile = path.join(dir, 'board.json');
const IDLE_MS = 2 * 60 * 60 * 1000;

if (flag('--stop')) {
  let info;
  try { info = JSON.parse(fs.readFileSync(infoFile, 'utf8')); } catch { console.log('no board running'); process.exit(0); }
  const req = http.request({ host: '127.0.0.1', port: info.port, path: `/shutdown?t=${info.token}`, method: 'POST' },
    () => { console.log('board stopped'); process.exit(0); });
  req.on('error', () => { console.log('board was not running'); process.exit(0); });
  req.end();
  return;
}

fs.mkdirSync(screensDir, { recursive: true });
const token = crypto.randomBytes(16).toString('hex');

function tokenOk(url) {
  const given = Buffer.from(url.searchParams.get('t') || '');
  const want = Buffer.from(token);
  return given.length === want.length && crypto.timingSafeEqual(given, want);
}

function newestScreen() {
  let best = null;
  for (const name of fs.readdirSync(screensDir)) {
    if (!name.endsWith('.html')) continue;
    const mtime = fs.statSync(path.join(screensDir, name)).mtimeMs;
    if (!best || mtime > best.mtime) best = { name, mtime };
  }
  return best;
}

const SHELL = `<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Visual board</title>
<style>
:root{--bg:#f7f7f8;--card:#fff;--text:#18181b;--muted:#71717a;--line:#e4e4e7;--accent:#f97316}
@media (prefers-color-scheme:dark){:root{--bg:#111113;--card:#1c1c1f;--text:#f4f4f5;--muted:#a1a1aa;--line:#2e2e33}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font:15px/1.5 system-ui,sans-serif}
header{display:flex;justify-content:space-between;align-items:center;padding:10px 20px;border-bottom:1px solid var(--line);color:var(--muted);font-size:13px}
main{max-width:1200px;margin:0 auto;padding:24px 20px 120px}
h1,h2,h3{line-height:1.25}.muted{color:var(--muted)}
.options,.cards{display:grid;gap:16px;grid-template-columns:repeat(auto-fit,minmax(240px,1fr))}
.split{display:grid;gap:16px;grid-template-columns:1fr 1fr}@media (max-width:760px){.split{grid-template-columns:1fr}}
.option,.card,.panel{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:16px}
.mock{background:var(--card);border:1px solid var(--line);border-radius:12px;overflow:hidden;min-height:200px}
[data-choice]{cursor:pointer;transition:border-color .15s,box-shadow .15s}
[data-choice]:hover{border-color:var(--muted)}
[data-choice].picked{border-color:var(--accent);box-shadow:0 0 0 2px var(--accent)}
img{max-width:100%;height:auto;border-radius:8px}
footer{position:fixed;left:0;right:0;bottom:0;background:var(--card);border-top:1px solid var(--line);padding:10px 20px;display:flex;gap:8px}
footer input{flex:1;padding:8px 10px;border:1px solid var(--line);border-radius:8px;background:var(--bg);color:var(--text)}
footer button{padding:8px 14px;border:0;border-radius:8px;background:var(--accent);color:#fff;cursor:pointer}
#status{font-size:12px}
</style></head><body>
<header><span id="screen">waiting for the first screen…</span><span id="status"></span></header>
<main id="content"><p class="muted">Claude will put the first screen here.</p></main>
<footer><input id="note" placeholder="Comment for Claude (optional) — Enter to send">
<button id="send">Send</button></footer>
<script>
const T=new URLSearchParams(location.search).get('t');let version='';let screen='';
const $=(id)=>document.getElementById(id);
async function post(body){
  const r=await fetch('/choice?t='+T,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
  $('status').textContent=r.ok?'sent ✓':'not sent';setTimeout(()=>$('status').textContent='',2000);
}
document.addEventListener('click',(e)=>{
  const el=e.target.closest('[data-choice]');if(!el)return;
  const group=el.closest('[data-multiselect]');
  if(!group)document.querySelectorAll('[data-choice].picked').forEach(x=>{if(x!==el)x.classList.remove('picked')});
  el.classList.toggle('picked');
  post({screen,choice:el.dataset.choice,picked:el.classList.contains('picked'),label:(el.querySelector('h3,h2,strong')||el).textContent.trim().slice(0,120)});
});
function sendNote(){const v=$('note').value.trim();if(!v)return;post({screen,note:v});$('note').value='';}
$('send').onclick=sendNote;$('note').addEventListener('keydown',(e)=>{if(e.key==='Enter')sendNote()});
async function poll(){
  try{
    const r=await fetch('/version?t='+T);const v=await r.json();
    if(v.version&&v.version!==version){
      const html=await (await fetch('/screen?t='+T)).text();
      version=v.version;screen=v.name;$('screen').textContent=v.name;
      const doc=new DOMParser().parseFromString(html,'text/html');
      $('content').replaceChildren(...doc.body.childNodes);
      doc.head.querySelectorAll('style').forEach(s=>$('content').prepend(s));
      $('content').querySelectorAll('[src^="files/"],[href^="files/"]').forEach(el=>{
        const a=el.hasAttribute('src')?'src':'href';el.setAttribute(a,'/'+el.getAttribute(a)+'?t='+T);
      });
      window.scrollTo(0,0);
    }
    $('status').textContent=$('status').textContent==='offline'?'':$('status').textContent;
  }catch{ $('status').textContent='offline'; }
  setTimeout(poll,1000);
}
poll();
</script></body></html>`;

let idleTimer;
function touch() { clearTimeout(idleTimer); idleTimer = setTimeout(() => shutdown('idle'), IDLE_MS); }

function shutdown(reason) {
  try { fs.unlinkSync(infoFile); } catch { /* already gone */ }
  console.log(JSON.stringify({ type: 'board-stopped', reason }));
  process.exit(0);
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://127.0.0.1');
  if (!tokenOk(url)) { res.writeHead(403); res.end('forbidden'); return; }
  touch();
  const send = (code, type, body) => { res.writeHead(code, { 'Content-Type': type, 'Cache-Control': 'no-store' }); res.end(body); };

  if (req.method === 'GET' && url.pathname === '/') return send(200, 'text/html; charset=utf-8', SHELL);
  if (req.method === 'GET' && url.pathname === '/version') {
    const s = newestScreen();
    return send(200, 'application/json', JSON.stringify(s ? { version: `${s.name}:${s.mtime}`, name: s.name } : {}));
  }
  if (req.method === 'GET' && url.pathname === '/screen') {
    const s = newestScreen();
    return send(200, 'text/html; charset=utf-8', s ? fs.readFileSync(path.join(screensDir, s.name), 'utf8') : '');
  }
  if (req.method === 'GET' && url.pathname.startsWith('/files/')) {
    // images and other assets placed next to the screens, e.g. <img src="files/mock-a.png?t=...">
    const file = path.resolve(screensDir, decodeURIComponent(url.pathname.slice('/files/'.length)));
    if (!file.startsWith(screensDir + path.sep) || !fs.existsSync(file)) return send(404, 'text/plain', 'not found');
    const types = { '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.webp': 'image/webp', '.svg': 'image/svg+xml', '.css': 'text/css' };
    return send(200, types[path.extname(file).toLowerCase()] || 'application/octet-stream', fs.readFileSync(file));
  }
  if (req.method === 'POST' && url.pathname === '/choice') {
    let body = '';
    req.on('data', (c) => { body += c; if (body.length > 64 * 1024) req.destroy(); });
    req.on('end', () => {
      let event;
      try { event = JSON.parse(body); } catch { return send(400, 'text/plain', 'bad json'); }
      fs.appendFileSync(choicesFile, JSON.stringify({ at: new Date().toISOString(), ...event }) + '\n');
      send(204, 'text/plain', '');
    });
    return;
  }
  if (req.method === 'POST' && url.pathname === '/shutdown') { send(204, 'text/plain', ''); setTimeout(() => shutdown('stopped'), 50); return; }
  send(404, 'text/plain', 'not found');
});

server.listen(Number(opt('--port', 0)), '127.0.0.1', () => {
  const port = server.address().port;
  const info = { type: 'board-started', url: `http://127.0.0.1:${port}/?t=${token}`, port, token, pid: process.pid, screens: screensDir, choices: choicesFile };
  fs.writeFileSync(infoFile, JSON.stringify(info, null, 2));
  console.log(JSON.stringify(info));
  touch();
  if (flag('--open')) {
    const cmd = process.platform === 'win32' ? ['cmd', ['/c', 'start', '', info.url]]
      : process.platform === 'darwin' ? ['open', [info.url]] : ['xdg-open', [info.url]];
    try { spawn(cmd[0], cmd[1], { stdio: 'ignore', detached: true }).unref(); } catch { /* the owner can open the URL */ }
  }
});
