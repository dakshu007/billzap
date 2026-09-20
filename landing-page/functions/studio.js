// The studio: login page and dashboard, served from one function.
//
// It lives at /s/<ADMIN_PATH>. Any other /s/… returns a flat 404 with
// nothing to suggest a studio exists, so scanning for it yields
// nothing. The secret path is not the security — the password is —
// but it keeps the login form off the open web and out of crawlers.
import { isAuthed, pathMatches } from './lib/auth.js';
import { BASE_CSS, DASHBOARD } from './lib/studio-ui.js';

const html = (status, body) => ({
  statusCode: status,
  headers: {
    'Content-Type': 'text/html; charset=utf-8',
    'Cache-Control': 'no-store',
    'X-Robots-Tag': 'noindex, nofollow, noarchive',
    'Referrer-Policy': 'no-referrer',   // keeps the secret path out of referrers
  },
  body,
});

export async function handler(event) {
  const seg = (event.path || '').replace(/^\/s\/?/, '').replace(/\/+$/, '');
  if (!pathMatches(seg)) {
    return {
      statusCode: 404,
      headers: { 'Content-Type': 'text/html; charset=utf-8' },
      body: '<!doctype html><meta charset="utf-8"><title>Not found</title><h1>404</h1>',
    };
  }
  return html(200, isAuthed(event.headers || {}) ? DASHBOARD : LOGIN);
}

const LOGIN = `<!doctype html><html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex,nofollow"><title>Sign in</title>
<link rel="icon" href="/assets/icon-32.png">
<style>${BASE_CSS}
body{display:grid;place-items:center;min-height:100dvh;padding:24px}
.card{width:min(400px,100%);background:var(--pap);border-radius:var(--r-l);
  padding:38px 34px;box-shadow:var(--sh-l);text-align:center}
.mark{width:56px;height:56px;margin:0 auto 20px;border-radius:16px;
  background:var(--jade-l);display:grid;place-items:center}
.mark img{width:34px;height:34px;border-radius:9px}
h1{font-size:23px;font-weight:800;letter-spacing:-.02em}
.sub{color:var(--mut);font-size:14.5px;margin-top:8px;margin-bottom:26px}
form{text-align:left}
.err{background:#FDF4F4;border:1px solid #F3D4D4;color:var(--red);
  border-radius:var(--r);padding:11px 14px;font-size:14px;margin-bottom:16px;display:none}
.err.on{display:block}
.card .btn{width:100%;padding:13px}
</style></head><body>
<div class="card">
  <div class="mark"><img src="/assets/icon-68.png" alt=""></div>
  <h1>BillZap Studio</h1>
  <p class="sub">Sign in to write and publish.</p>
  <form id="f">
    <div class="err" id="e"></div>
    <div class="field">
      <label for="p">Password</label>
      <input id="p" type="password" autocomplete="current-password" required autofocus>
    </div>
    <button class="btn btn-p" id="go" type="submit">Sign in</button>
  </form>
</div>
<script>
const f=document.getElementById('f'),e=document.getElementById('e'),go=document.getElementById('go');
f.onsubmit=async(ev)=>{ev.preventDefault();go.disabled=true;go.textContent='Checking…';e.className='err';
 try{
  const r=await fetch('/api/login',{method:'POST',headers:{'Content-Type':'application/json'},
    body:JSON.stringify({password:document.getElementById('p').value})});
  if(r.ok){location.reload();return;}
  const d=await r.json().catch(()=>({}));
  e.textContent=d.error||'That did not work.';e.className='err on';
 }catch(_){e.textContent='Could not reach the server.';e.className='err on';}
 go.disabled=false;go.textContent='Sign in';};
</script></body></html>`;
