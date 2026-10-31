// /try — BillZap in the browser, before anyone installs it.
//
// Two views of one URL:
//   - No session: the site's own page with a short form. Business name
//     and email, then a six-digit code from the email (api.js does the
//     sending and checking), then the demo.
//   - With a session (lib/try-session.js): the demo. On a computer the
//     app sits in a phone frame beside a "get it on your phone" panel
//     with a QR code; on a phone it fills the screen under a thin bar.
//
// The app itself is the Flutter web build of lib/main_demo.dart,
// served from /try/app/ (staged by the deploy workflow). It opens on a
// sample shop named after the business on the form.
import { CSS, header, footer, head } from './lib/shell.js';
import { esc } from './lib/html.js';
import { readTry } from './lib/try-session.js';

const SITE = 'https://billzap.app';
const PLAY = 'https://play.google.com/store/apps/details?id=com.billzap.app';
const play = (content) => `${PLAY}&referrer=${encodeURIComponent(
  `utm_source=billzap.app&utm_medium=try_demo&utm_content=${content}`)}`;

const ARROW = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6"/></svg>';
const BOLT = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M13 2 4 14h7l-1 8 9-12h-7l1-8z"/></svg>';

const page = (body) => ({
  statusCode: 200,
  headers: { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' },
  body,
});

export async function handler(event) {
  const session = readTry(event.headers || {});
  return page(session ? demo(session) : form(event.queryStringParameters || {}));
}

// ── The form ────────────────────────────────────────────────────────
function form(q) {
  const source = String(q.from || q.utm_source || '').slice(0, 80);
  const body = `
<section class="tf">
  <div class="tf-copy">
    <span class="tf-pill">${BOLT}<span>Live demo · no download</span></span>
    <h1>Try BillZap free in your browser</h1>
    <p class="tf-lede">Open a demo shop with your business name on it. Make a GST bill, see CGST and SGST worked out, the UPI QR, the PDF and your reports, in about a minute.</p>
    <ul class="tf-list">
      <li>Six months of sample bills, customers and stock already in it</li>
      <li>Make a real bill and download it as a PDF</li>
      <li>Like it? Install the free Android app and bill your own customers</li>
    </ul>
  </div>
  <div class="tf-card" id="tf-card">
    <form id="tf-start" novalidate>
      <h2>Open your demo shop</h2>
      <label>Business name
        <input name="business" autocomplete="organization" maxlength="60" placeholder="e.g. Sri Lakshmi Stores" required>
      </label>
      <label>Email
        <input name="email" type="email" autocomplete="email" inputmode="email" maxlength="254" placeholder="you@example.com" required>
      </label>
      <label class="tf-check"><input type="checkbox" name="marketing"> Send me tips on billing and GST, and BillZap updates (optional)</label>
      <input type="hidden" name="source" value="${esc(source)}">
      <button class="btn btn-primary btn-lg" type="submit">Open the demo <span class="chip">${ARROW}</span></button>
      <p class="tf-err" role="alert"></p>
      <p class="tf-fine">We email you a code to confirm the address. By continuing you agree to our <a href="/privacy/">privacy policy</a>. No spam, and you can ask us to delete your details any time at <a href="mailto:support@mykavo.app">support@mykavo.app</a>.</p>
    </form>
    <form id="tf-code" hidden novalidate>
      <h2>Check your email</h2>
      <p class="tf-sent">We sent a 6-digit code to <b id="tf-to"></b>. It expires in 10 minutes.</p>
      <label>Code
        <input name="code" inputmode="numeric" autocomplete="one-time-code" pattern="[0-9]*" maxlength="6" placeholder="••••••" required>
      </label>
      <button class="btn btn-primary btn-lg" type="submit">Verify and open <span class="chip">${ARROW}</span></button>
      <p class="tf-err" role="alert"></p>
      <p class="tf-fine"><a href="#" id="tf-again">Send a new code</a> · <a href="#" id="tf-back">Use a different email</a></p>
    </form>
  </div>
</section>
<style>
.tf{max-width:1120px;margin:0 auto;padding:clamp(28px,6vw,72px) 20px clamp(48px,7vw,88px);display:grid;grid-template-columns:1.1fr .9fr;gap:clamp(28px,5vw,64px);align-items:center}
.tf-pill{display:inline-flex;align-items:center;gap:8px;padding:6px 12px;border-radius:99px;background:var(--jade-50);color:var(--jade-700);font-weight:600;font-size:13px;border:1px solid var(--jade-100)}
.tf-pill svg{width:15px;height:15px}
.tf h1{font-family:'Jakarta','Jakarta Fallback',sans-serif;font-weight:800;font-size:clamp(32px,4.6vw,52px);line-height:1.08;letter-spacing:-.02em;color:var(--ink);margin:18px 0 14px}
.tf-lede{font-size:clamp(16px,1.6vw,18px);line-height:1.6;color:var(--ink-2);margin:0 0 18px;max-width:52ch}
.tf-list{margin:0;padding:0;list-style:none;display:grid;gap:10px}
.tf-list li{position:relative;padding-left:28px;color:var(--ink-2);line-height:1.5}
.tf-list li::before{content:'';position:absolute;left:0;top:3px;width:18px;height:18px;border-radius:50%;background:var(--jade-500) url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='white' stroke-width='3' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M5 12l5 5L20 7'/%3E%3C/svg%3E") center/12px no-repeat}
.tf-card{background:var(--paper);border:1px solid var(--line);border-radius:24px;padding:clamp(22px,3vw,32px);box-shadow:0 24px 60px -32px rgba(13,17,23,.25)}
.tf-card h2{font-family:'Jakarta','Jakarta Fallback',sans-serif;font-weight:800;font-size:22px;margin:0 0 18px;color:var(--ink)}
.tf-card form{display:grid;gap:14px}
.tf-card form[hidden]{display:none}
.tf>*{min-width:0}
.tf-card label{display:grid;gap:6px;font-weight:600;font-size:14px;color:var(--ink)}
.tf-card input[name=business],.tf-card input[name=email],.tf-card input[name=code]{font:inherit;font-weight:500;font-size:16px;padding:13px 14px;border-radius:12px;border:1.5px solid var(--line-2);background:var(--paper);color:var(--ink);outline:none;transition:border-color .15s,box-shadow .15s}
.tf-card input[name=code]{letter-spacing:.5em;font-size:22px;text-align:center}
.tf-card input:focus{border-color:var(--jade-500);box-shadow:0 0 0 4px rgba(16,165,111,.12)}
.tf-check{display:flex!important;grid-template-columns:none;align-items:flex-start;gap:10px!important;font-weight:400!important;color:var(--ink-2)!important;line-height:1.45}
.tf-check input{margin-top:3px;width:16px;height:16px;accent-color:var(--jade-600)}
.tf-card .btn{justify-content:space-between;width:100%}
.tf-card .btn[disabled]{opacity:.6;pointer-events:none}
.tf-err{margin:0;color:#B42318;font-size:14px;min-height:0}
.tf-err:empty{display:none}
.tf-fine,.tf-sent{margin:0;font-size:13px;line-height:1.55;color:var(--ink-3,#5b6470)}
.tf-sent{font-size:14.5px;color:var(--ink-2)}
.tf-fine a{color:var(--jade-700)}
@media (max-width:860px){.tf{grid-template-columns:minmax(0,1fr);padding-top:20px}.tf-list{display:none}.tf h1{font-size:clamp(28px,8vw,40px)}}
</style>
<script>
(function(){
  var start=document.getElementById('tf-start'), codeF=document.getElementById('tf-code');
  var email='';
  function err(f,m){f.querySelector('.tf-err').textContent=m||'';}
  function busy(f,b){var x=f.querySelector('button');x.disabled=b;}
  function post(path,data){return fetch('/api/try/'+path,{method:'POST',headers:{'Content-Type':'application/json'},
    body:JSON.stringify(data),credentials:'same-origin'}).then(function(r){return r.json().then(function(j){j._ok=r.ok;return j;});});}
  function ask(){
    var d={business:start.business.value,email:start.email.value,marketing:start.marketing.checked,source:start.source.value};
    if(d.business.trim().length<2){err(start,'Enter your business name.');start.business.focus();return;}
    if(!/^[^\\s@]+@[^\\s@]+\\.[^\\s@]{2,}$/.test(d.email.trim())){err(start,'Enter a valid email address.');start.email.focus();return;}
    err(start);busy(start,true);
    post('start',d).then(function(j){
      busy(start,false);
      if(!j._ok){err(start,j.error||'Something went wrong. Try again.');return;}
      if(!j.otp){location.reload();return;}
      email=d.email.trim();document.getElementById('tf-to').textContent=email;
      start.hidden=true;codeF.hidden=false;codeF.code.value='';codeF.code.focus();
    },function(){busy(start,false);err(start,'No connection. Try again.');});
  }
  start.addEventListener('submit',function(e){e.preventDefault();ask();});
  codeF.addEventListener('submit',function(e){
    e.preventDefault();var c=codeF.code.value.replace(/\\D/g,'');
    if(c.length!==6){err(codeF,'Enter the 6-digit code from the email.');return;}
    err(codeF);busy(codeF,true);
    post('verify',{email:email,code:c}).then(function(j){
      if(j._ok){location.reload();return;}
      busy(codeF,false);err(codeF,j.error||'That code isn\\'t right.');
    },function(){busy(codeF,false);err(codeF,'No connection. Try again.');});
  });
  codeF.code.addEventListener('input',function(){
    var v=codeF.code.value.replace(/\\D/g,'').slice(0,6);codeF.code.value=v;
    if(v.length===6)codeF.requestSubmit?codeF.requestSubmit():codeF.dispatchEvent(new Event('submit'));
  });
  document.getElementById('tf-again').addEventListener('click',function(e){e.preventDefault();codeF.hidden=true;start.hidden=false;ask();});
  document.getElementById('tf-back').addEventListener('click',function(e){e.preventDefault();codeF.hidden=true;start.hidden=false;start.email.focus();});
})();
</script>`;
  return `<!doctype html>
<html lang="en">
${head({
    title: 'Try BillZap Free in Your Browser: GST Billing App Demo',
    desc: 'Open a live demo of BillZap with your business name on it. Make a GST bill, see the UPI QR, PDF and reports, then get the free Android app.',
    canonical: `${SITE}/try`, css: CSS,
    robots: 'index,follow,max-image-preview:large,max-snippet:-1',
  })}
<body>
${header({ base: '/' })}
<main id="main">${body}</main>
${footer({ base: '/' })}
</body>
</html>`;
}

// ── The demo ────────────────────────────────────────────────────────
function demo(s) {
  const shop = String(s.shop || 'Your shop');
  const src = `/try/app/?shop=${encodeURIComponent(shop)}`;
  return `<!doctype html>
<html lang="en">
${head({
    title: `${esc(shop)} · BillZap demo`,
    desc: 'Your BillZap demo shop.',
    canonical: `${SITE}/try`, css: CSS, robots: 'noindex,nofollow',
  })}
<body class="tz-body">
<div class="tz">
  <header class="tz-bar">
    <a class="tz-logo" href="/" aria-label="BillZap home"><img class="tz-mark" src="/assets/logo-68.png" alt="" width="30" height="30"><b>BillZap</b></a>
    <span class="tz-demo">Demo</span>
    <span class="tz-shop">${esc(shop)}</span>
    <span class="tz-gap"></span>
    <button class="tz-ghost" type="button" id="tz-restart" title="Start the demo shop again">Start over</button>
    <a class="btn btn-primary tz-get" href="${play('top_bar')}" rel="noopener" target="_blank">Get the app <span class="chip">${ARROW}</span></a>
  </header>
  <div class="tz-main">
    <div class="tz-phone">
      <iframe id="tz-app" src="${esc(src)}" title="BillZap demo app" allow="clipboard-write"></iframe>
    </div>
    <aside class="tz-side">
      <h1>Welcome to ${esc(shop)}'s demo shop</h1>
      <p>Everything here is sample data. Try it the way you would at your counter:</p>
      <ol>
        <li>Tap <b>New Invoice</b>, pick a customer and add a few items</li>
        <li>Watch CGST and SGST work themselves out, then save</li>
        <li>Open the bill: UPI QR for the exact amount, PDF download</li>
        <li>Check <b>Reports</b> for sales, GST collected and profit</li>
      </ol>
      <div class="tz-qr">
        <img src="/assets/try-play-qr.svg" width="132" height="132" alt="QR code for BillZap on Google Play">
        <div><b>Bill your own customers</b><span>Scan with your phone camera to install BillZap free from Google Play.</span></div>
      </div>
      <a class="btn btn-primary btn-lg" href="${play('side_panel')}" rel="noopener" target="_blank">Download free on Google Play <span class="chip">${ARROW}</span></a>
      <p class="tz-fine">Free · No sign-up · Works offline · Android</p>
    </aside>
  </div>
</div>
<style>
html,body.tz-body{height:100%;margin:0;background:var(--canvas)}
.tz{display:flex;flex-direction:column;height:100dvh;min-height:100%}
.tz-bar{display:flex;align-items:center;gap:12px;padding:10px clamp(12px,3vw,28px);background:var(--paper);border-bottom:1px solid var(--line)}
.tz-logo{display:flex;align-items:center;gap:8px;color:var(--ink);text-decoration:none;font-family:'Jakarta','Jakarta Fallback',sans-serif;font-size:18px}
.tz-mark{width:30px;height:30px;border-radius:8px;display:block}
.tz-demo{font-size:11.5px;font-weight:700;letter-spacing:.06em;text-transform:uppercase;color:var(--jade-700);background:var(--jade-50);border:1px solid var(--jade-100);padding:3px 8px;border-radius:99px}
.tz-shop{color:var(--ink-2);font-size:14px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;min-width:0}
.tz-gap{flex:1}
.tz-ghost{font:inherit;font-size:14px;font-weight:600;color:var(--ink-2);background:none;border:1px solid var(--line-2);border-radius:99px;padding:8px 14px;cursor:pointer}
.tz-ghost:hover{border-color:var(--jade-500);color:var(--jade-700)}
.tz-main{flex:1;display:flex;align-items:center;justify-content:center;gap:clamp(28px,5vw,72px);padding:clamp(16px,3vh,32px) 20px;min-height:0}
.tz-phone{width:390px;height:min(820px,calc(100dvh - 120px));flex:none;border-radius:44px;padding:12px;background:#0D1117;box-shadow:0 40px 80px -40px rgba(13,17,23,.55),inset 0 0 0 2px #2a313b}
.tz-phone iframe{width:100%;height:100%;border:0;border-radius:32px;background:#F7F8F7;display:block}
.tz-side{max-width:400px}
.tz-side h1{font-family:'Jakarta','Jakarta Fallback',sans-serif;font-weight:800;font-size:clamp(24px,2.4vw,32px);line-height:1.15;letter-spacing:-.015em;color:var(--ink);margin:0 0 10px}
.tz-side p{color:var(--ink-2);line-height:1.55;margin:0 0 12px}
.tz-side ol{list-style:decimal;margin:0 0 22px;padding-left:20px;color:var(--ink-2);line-height:1.55;display:grid;gap:6px}
.tz-qr{display:flex;gap:16px;align-items:center;background:var(--paper);border:1px solid var(--line);border-radius:18px;padding:14px;margin-bottom:16px}
.tz-qr img{width:112px;height:112px;flex:none;image-rendering:pixelated}
.tz-qr b{display:block;color:var(--ink);margin-bottom:4px}
.tz-qr span{color:var(--ink-2);font-size:14px;line-height:1.5}
.tz-side .btn{width:100%;justify-content:space-between}
.tz-fine{font-size:13px!important;text-align:center;margin-top:10px!important}
@media (max-width:860px){
  .tz-side,.tz-shop,.tz-ghost{display:none}
  .tz-bar{padding:8px 12px}
  .tz-main{padding:0;display:block}
  .tz-phone{width:auto;height:100%;border-radius:0;padding:0;background:none;box-shadow:none}
  .tz-phone iframe{border-radius:0}
  .tz-get{padding:8px 6px 8px 14px;font-size:14px}
}
</style>
<script>
document.getElementById('tz-restart').addEventListener('click',function(){
  var f=document.getElementById('tz-app'); f.src=f.src;
});
</script>
</body>
</html>`;
}
