// The studio's markup, styles and behaviour.
//
// One self-contained page, no framework and no build step. It is
// served by studio.js and talks to /api/*. Keeping it dependency-free
// means it cannot drift out of step with a bundler config, and the
// whole editor is readable in one file.
//
// The editor is contenteditable driven through execCommand. That API
// is formally deprecated and there is no replacement with the same
// browser support; every rich-text editor worth using still leans on
// it. Whatever it produces is passed through the allowlist in
// html.js before it is ever stored, so a paste from another site
// arrives as plain, safe markup.

export const BASE_CSS = `
*{margin:0;padding:0;box-sizing:border-box}
:root{
  --jade:#0A8A5F;--jade-d:#066B4A;--jade-l:#EBFAF3;--jade-b:#D3F3E5;
  --ink:#0C1014;--ink-2:#232B35;--mut:#6B7585;--mut-2:#98A1AE;
  --pap:#fff;--can:#F6F7F9;--sun:#EEF0F4;--line:#E3E7EC;
  --red:#C53434;--amber:#B7791F;
  --r:14px;--r-l:20px;
  --sh:0 1px 2px rgba(12,16,20,.04),0 2px 8px rgba(12,16,20,.05);
  --sh-l:0 4px 8px rgba(12,16,20,.05),0 24px 60px rgba(12,16,20,.10);
}
body{font-family:'Plus Jakarta Sans',ui-sans-serif,system-ui,-apple-system,'Segoe UI',Roboto,sans-serif;
  background:var(--can);color:var(--ink);-webkit-font-smoothing:antialiased;line-height:1.55}
a{color:var(--jade-d);text-decoration:none}
button,input,textarea,select{font:inherit;color:inherit}
button{cursor:pointer;border:0;background:none}
.btn{display:inline-flex;align-items:center;justify-content:center;gap:8px;
  padding:11px 18px;border-radius:var(--r);font-size:14.5px;font-weight:600;
  border:1.5px solid transparent;transition:.16s;white-space:nowrap}
.btn-p{background:var(--jade-d);color:#fff}
.btn-p:hover{background:#055C3F}
.btn-g{background:var(--pap);border-color:var(--line);color:var(--ink)}
.btn-g:hover{border-color:var(--mut-2)}
.btn-d{background:var(--pap);border-color:#F3D4D4;color:var(--red)}
.btn-d:hover{background:#FDF4F4}
.btn[disabled]{opacity:.55;pointer-events:none}
input[type=text],input[type=password],textarea,select{
  width:100%;padding:11px 13px;background:var(--can);border:1.5px solid var(--line);
  border-radius:var(--r);outline:0;transition:.16s}
input:focus,textarea:focus,select:focus{background:var(--pap);border-color:var(--jade);
  box-shadow:0 0 0 4px rgba(16,165,111,.15)}
label{display:block;font-size:12.5px;font-weight:600;letter-spacing:.03em;
  text-transform:uppercase;color:var(--mut);margin-bottom:7px}
.field{margin-bottom:18px}
.hint{font-size:13px;color:var(--mut);margin-top:6px}
`;

const APP_CSS = `
.top{position:sticky;top:0;z-index:40;background:rgba(255,255,255,.88);
  backdrop-filter:saturate(180%) blur(14px);border-bottom:1px solid var(--line)}
.top-in{max-width:1180px;margin:0 auto;padding:0 20px;height:62px;
  display:flex;align-items:center;gap:14px}
.brand{display:flex;align-items:center;gap:10px;font-weight:800;letter-spacing:-.02em}
.brand img{width:30px;height:30px;border-radius:9px}
.brand span{color:var(--mut-2);font-weight:600}
.top .sp{margin-left:auto}
.wrap{max-width:1180px;margin:0 auto;padding:clamp(22px,4vw,36px) 20px 80px}

.head{display:flex;align-items:flex-end;gap:16px;flex-wrap:wrap;margin-bottom:24px}
.head h1{font-size:clamp(25px,4vw,33px);font-weight:800;letter-spacing:-.03em}
.head p{color:var(--mut);margin-top:5px;font-size:15px}
.head .sp{margin-left:auto}

.tabs{display:flex;gap:4px;background:var(--sun);padding:4px;border-radius:var(--r);
  margin-bottom:22px;width:fit-content}
.tabs button{padding:8px 16px;border-radius:10px;font-size:14px;font-weight:600;color:var(--mut)}
.tabs button.on{background:var(--pap);color:var(--ink);box-shadow:var(--sh)}

.cards{display:grid;gap:12px}
.row{background:var(--pap);border:1px solid var(--line);border-radius:var(--r);
  padding:16px 18px;display:flex;align-items:center;gap:16px;transition:.16s}
.row:hover{border-color:var(--mut-2);box-shadow:var(--sh)}
.row-thumb{width:64px;height:44px;border-radius:9px;object-fit:cover;background:var(--sun);flex:none}
.row-main{min-width:0;flex:1}
.row-main h3{font-size:16px;font-weight:700;letter-spacing:-.01em;
  white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.row-main p{font-size:13.5px;color:var(--mut);margin-top:3px;
  white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.row-acts{display:flex;gap:8px;flex:none}
.row-acts .btn{padding:8px 13px;font-size:13.5px}
.pill{display:inline-block;padding:3px 9px;border-radius:999px;font-size:11.5px;
  font-weight:700;letter-spacing:.03em;text-transform:uppercase}
.pill-pub{background:var(--jade-l);color:var(--jade-d)}
.pill-dr{background:#FDF3E3;color:#8A5A12}
.empty{background:var(--pap);border:1px dashed var(--line);border-radius:var(--r-l);
  padding:clamp(34px,6vw,54px);text-align:center}
.empty h3{font-size:19px;font-weight:700}
.empty p{color:var(--mut);margin-top:9px}
.empty .btn{margin-top:20px}

/* editor */
.ed{display:grid;grid-template-columns:1fr 320px;gap:22px;align-items:start}
@media (max-width:940px){.ed{grid-template-columns:1fr}}
.panel{background:var(--pap);border:1px solid var(--line);border-radius:var(--r-l);
  padding:clamp(18px,3vw,26px);box-shadow:var(--sh)}
.panel + .panel{margin-top:16px}
.panel h2{font-size:15px;font-weight:700;margin-bottom:16px;letter-spacing:-.01em}
#title{font-size:clamp(21px,3vw,27px);font-weight:800;letter-spacing:-.025em;
  padding:14px;background:var(--can)}
.slug{display:flex;align-items:center;gap:0;font-size:13.5px;color:var(--mut)}
.slug span{padding:11px 0 11px 13px;background:var(--can);border:1.5px solid var(--line);
  border-right:0;border-radius:var(--r) 0 0 var(--r);white-space:nowrap}
.slug input{border-radius:0 var(--r) var(--r) 0;border-left:0}

.tb{display:flex;flex-wrap:wrap;gap:3px;padding:8px;background:var(--can);
  border:1.5px solid var(--line);border-bottom:0;border-radius:var(--r) var(--r) 0 0;
  position:sticky;top:62px;z-index:20}
.tb button{width:34px;height:34px;border-radius:9px;display:grid;place-items:center;
  color:var(--ink-2);font-size:14px;font-weight:700;transition:.14s}
.tb button:hover{background:var(--sun)}
.tb button.on{background:var(--jade-l);color:var(--jade-d)}
.tb .sep{width:1px;height:22px;background:var(--line);margin:6px 5px;align-self:center}
.tb svg{width:17px;height:17px;fill:none;stroke:currentColor;stroke-width:2;
  stroke-linecap:round;stroke-linejoin:round}
#body{min-height:460px;padding:22px;background:var(--pap);border:1.5px solid var(--line);
  border-radius:0 0 var(--r) var(--r);outline:0;font-size:17px;line-height:1.75;color:var(--ink-2)}
#body:focus{border-color:var(--jade)}
#body:empty::before{content:attr(data-ph);color:var(--mut-2)}
#body h2{font-size:25px;font-weight:800;margin:28px 0 0;color:var(--ink);letter-spacing:-.02em}
#body h3{font-size:20px;font-weight:700;margin:24px 0 0;color:var(--ink)}
#body p{margin-top:15px}
#body ul,#body ol{margin:15px 0 0 24px}
#body li{margin-top:7px}
#body blockquote{margin:20px 0 0;padding:4px 0 4px 20px;border-left:3px solid var(--jade);
  color:var(--ink-2)}
#body pre{margin-top:18px;padding:16px;background:var(--ink);color:#E8EDF2;
  border-radius:12px;overflow-x:auto;font-size:14px;font-family:ui-monospace,monospace}
#body img{max-width:100%;height:auto;border-radius:12px;margin-top:18px}
#body a{text-decoration:underline}
#body hr{margin:26px 0;border:0;border-top:1px solid var(--line)}

.side .field:last-child{margin-bottom:0}
.statusrow{display:flex;gap:8px}
.statusrow button{flex:1;padding:10px;border-radius:11px;font-size:13.5px;font-weight:600;
  border:1.5px solid var(--line);background:var(--can);color:var(--mut)}
.statusrow button.on{background:var(--jade-l);border-color:var(--jade-b);color:var(--jade-d)}
.cover{aspect-ratio:16/9;border-radius:12px;background:var(--can);border:1.5px dashed var(--line);
  display:grid;place-items:center;overflow:hidden;cursor:pointer;color:var(--mut);font-size:13.5px}
.cover img{width:100%;height:100%;object-fit:cover}
.bar{position:fixed;left:0;right:0;bottom:0;z-index:50;background:rgba(255,255,255,.94);
  backdrop-filter:blur(14px);border-top:1px solid var(--line);padding:12px 20px}
.bar-in{max-width:1180px;margin:0 auto;display:flex;align-items:center;gap:12px}
.bar .sp{margin-left:auto}
.saved{font-size:13.5px;color:var(--mut)}
.toast{position:fixed;left:50%;bottom:88px;transform:translateX(-50%) translateY(12px);
  background:var(--ink);color:#fff;padding:12px 20px;border-radius:999px;font-size:14px;
  font-weight:600;opacity:0;pointer-events:none;transition:.24s;z-index:60}
.toast.on{opacity:1;transform:translateX(-50%) translateY(0)}
.toast.bad{background:var(--red)}
.hidden{display:none!important}
.spin{width:15px;height:15px;border:2px solid rgba(255,255,255,.35);border-top-color:#fff;
  border-radius:50%;animation:sp .7s linear infinite}
@keyframes sp{to{transform:rotate(360deg)}}
`;

const ICON = (d) => `<svg viewBox="0 0 24 24" aria-hidden="true">${d}</svg>`;
const I = {
  bold: '<path d="M6 4h8a4 4 0 0 1 0 8H6z"/><path d="M6 12h9a4 4 0 0 1 0 8H6z"/>',
  italic: '<line x1="19" y1="4" x2="10" y2="4"/><line x1="14" y1="20" x2="5" y2="20"/><line x1="15" y1="4" x2="9" y2="20"/>',
  ul: '<line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><circle cx="3.5" cy="6" r="1.2"/><circle cx="3.5" cy="12" r="1.2"/><circle cx="3.5" cy="18" r="1.2"/>',
  ol: '<line x1="10" y1="6" x2="21" y2="6"/><line x1="10" y1="12" x2="21" y2="12"/><line x1="10" y1="18" x2="21" y2="18"/><path d="M4 6h1V3H4"/><path d="M4 10h2l-2 3h2"/><path d="M4 17h2v1H4v1h2"/>',
  quote: '<path d="M3 21c3 0 7-1 7-8V5H3v7h4c0 4-2 5-4 5z"/><path d="M14 21c3 0 7-1 7-8V5h-7v7h4c0 4-2 5-4 5z"/>',
  link: '<path d="M10 13a5 5 0 0 0 7.5.5l3-3a5 5 0 0 0-7-7l-1.7 1.7"/><path d="M14 11a5 5 0 0 0-7.5-.5l-3 3a5 5 0 0 0 7 7l1.7-1.7"/>',
  img: '<rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-4.6-4.6a2 2 0 0 0-2.8 0L3 21"/>',
  code: '<polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/>',
  hr: '<line x1="3" y1="12" x2="21" y2="12"/>',
  undo: '<path d="M3 7v6h6"/><path d="M3 13a9 9 0 1 0 3-7.7L3 8"/>',
  redo: '<path d="M21 7v6h-6"/><path d="M21 13a9 9 0 1 1-3-7.7L21 8"/>',
  clear: '<path d="M3 6h18"/><path d="M8 6V4h8v2"/><path d="M19 6v14H5V6"/>',
};

export const DASHBOARD = `<!doctype html><html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex,nofollow"><title>BillZap Studio</title>
<link rel="icon" href="/assets/icon-32.png">
<style>${BASE_CSS}${APP_CSS}</style>
</head><body>

<header class="top"><div class="top-in">
  <a class="brand" href="#"><img src="/assets/icon-68.png" alt=""> BillZap <span>Studio</span></a>
  <div class="sp"></div>
  <a class="btn btn-g" href="/blog" target="_blank" rel="noopener">View blog</a>
  <button class="btn btn-g" id="out">Sign out</button>
</div></header>

<!-- ── list ──────────────────────────────────────────────────── -->
<div class="wrap" id="view-list">
  <div class="head">
    <div><h1>Posts</h1><p id="count">Loading…</p></div>
    <div class="sp"></div>
    <button class="btn btn-p" id="new">Write a new post</button>
  </div>
  <div class="tabs" id="filters">
    <button data-f="all" class="on">All</button>
    <button data-f="published">Published</button>
    <button data-f="draft">Drafts</button>
  </div>
  <div class="cards" id="rows"></div>
</div>

<!-- ── editor ────────────────────────────────────────────────── -->
<div class="wrap hidden" id="view-edit">
  <div class="head">
    <div><h1 id="edTitle">New post</h1><p id="edSub">Not saved yet</p></div>
    <div class="sp"></div>
    <button class="btn btn-g" id="back">← All posts</button>
  </div>

  <div class="ed">
    <div>
      <div class="panel">
        <div class="field"><label for="title">Title</label>
          <input id="title" type="text" placeholder="How to make a GST invoice in 30 seconds"></div>
        <div class="field" style="margin-bottom:0"><label for="slug">Web address</label>
          <div class="slug"><span>billzap.netlify.app/blog/</span><input id="slug" type="text" placeholder="auto"></div>
        </div>
      </div>

      <div class="panel" style="padding:0;overflow:hidden">
        <div class="tb" id="tb">
          <button data-c="bold" title="Bold (Ctrl+B)">${ICON(I.bold)}</button>
          <button data-c="italic" title="Italic (Ctrl+I)">${ICON(I.italic)}</button>
          <span class="sep"></span>
          <button data-b="h2" title="Heading">H2</button>
          <button data-b="h3" title="Subheading">H3</button>
          <button data-b="p" title="Paragraph">P</button>
          <span class="sep"></span>
          <button data-c="insertUnorderedList" title="Bulleted list">${ICON(I.ul)}</button>
          <button data-c="insertOrderedList" title="Numbered list">${ICON(I.ol)}</button>
          <button data-b="blockquote" title="Quote">${ICON(I.quote)}</button>
          <button data-b="pre" title="Code block">${ICON(I.code)}</button>
          <span class="sep"></span>
          <button id="bLink" title="Link (Ctrl+K)">${ICON(I.link)}</button>
          <button id="bImg" title="Insert image">${ICON(I.img)}</button>
          <button id="bHr" title="Divider">${ICON(I.hr)}</button>
          <span class="sep"></span>
          <button data-c="undo" title="Undo">${ICON(I.undo)}</button>
          <button data-c="redo" title="Redo">${ICON(I.redo)}</button>
          <button data-c="removeFormat" title="Clear formatting">${ICON(I.clear)}</button>
        </div>
        <div id="body" contenteditable="true" data-ph="Start writing…"></div>
      </div>
    </div>

    <div class="side">
      <div class="panel">
        <h2>Publishing</h2>
        <div class="field">
          <label>Status</label>
          <div class="statusrow" id="statusRow">
            <button data-s="draft" class="on">Draft</button>
            <button data-s="published">Published</button>
          </div>
          <p class="hint" id="statusHint">Only you can see a draft.</p>
        </div>
        <div class="field" style="margin-bottom:0">
          <label for="tags">Tags</label>
          <input id="tags" type="text" placeholder="GST, invoicing">
          <p class="hint">Comma separated.</p>
        </div>
      </div>

      <div class="panel">
        <h2>Cover image</h2>
        <div class="cover" id="cover">Click to upload</div>
        <input type="file" id="coverFile" accept="image/*" class="hidden">
        <div class="field" style="margin-top:14px;margin-bottom:0">
          <label for="coverAlt">Describe the image</label>
          <input id="coverAlt" type="text" placeholder="A shopkeeper using BillZap">
          <p class="hint">Read aloud to people using a screen reader.</p>
        </div>
        <button class="btn btn-g" id="coverClear" style="width:100%;margin-top:12px">Remove cover</button>
      </div>

      <div class="panel">
        <h2>Search appearance</h2>
        <div class="field"><label for="excerpt">Summary</label>
          <textarea id="excerpt" rows="3" placeholder="Shown on the blog list."></textarea></div>
        <div class="field"><label for="metaTitle">Meta title</label>
          <input id="metaTitle" type="text" placeholder="Defaults to the post title"></div>
        <div class="field" style="margin-bottom:0"><label for="metaDesc">Meta description</label>
          <textarea id="metaDesc" rows="3" placeholder="Defaults to the summary"></textarea>
          <p class="hint"><span id="mdCount">0</span>/160 characters</p></div>
      </div>
    </div>
  </div>
</div>

<div class="bar hidden" id="bar"><div class="bar-in">
  <span class="saved" id="saved">Not saved yet</span>
  <div class="sp"></div>
  <button class="btn btn-d" id="del">Delete</button>
  <button class="btn btn-g" id="saveDraft">Save draft</button>
  <button class="btn btn-p" id="publish">Publish</button>
</div></div>

<div class="toast" id="toast"></div>

<script>
${'/* ── state ── */'}
let posts=[], cur=null, filter='all', dirty=false;
const $=(id)=>document.getElementById(id);
const api=async(path,opt={})=>{
  const r=await fetch('/api/'+path,{headers:{'Content-Type':'application/json'},...opt});
  if(r.status===401){location.reload();throw new Error('signed out');}
  const d=await r.json().catch(()=>({}));
  if(!r.ok) throw new Error(d.error||('HTTP '+r.status));
  return d;
};
const toast=(msg,bad)=>{const t=$('toast');t.textContent=msg;t.className='toast on'+(bad?' bad':'');
  clearTimeout(t._t);t._t=setTimeout(()=>{t.className='toast';},2600);};
const esc=(s)=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const when=(d)=>d?new Date(d).toLocaleDateString('en-GB',{day:'numeric',month:'short',year:'numeric'}):'—';

${'/* ── list ── */'}
async function load(){
  try{
    const d=await api('posts');
    posts=d.posts||[];
    const pub=posts.filter(p=>p.status==='published').length;
    $('count').textContent=posts.length
      ? posts.length+' post'+(posts.length===1?'':'s')+' · '+pub+' published'
      : 'Nothing written yet';
    draw();
  }catch(e){ toast(e.message,true); }
}
function draw(){
  const list=posts.filter(p=>filter==='all'||p.status===filter);
  if(!list.length){
    $('rows').innerHTML='<div class="empty"><h3>Nothing here yet</h3>'+
      '<p>Write your first post and it appears on billzap.netlify.app/blog the moment you publish.</p>'+
      '<button class="btn btn-p" onclick="openEditor()">Write a new post</button></div>';
    return;
  }
  $('rows').innerHTML=list.map(p=>\`
    <div class="row">
      \${p.cover_url?\`<img class="row-thumb" src="\${esc(p.cover_url)}" alt="">\`:'<div class="row-thumb"></div>'}
      <div class="row-main">
        <h3>\${esc(p.title)}</h3>
        <p><span class="pill \${p.status==='published'?'pill-pub':'pill-dr'}">\${p.status}</span>
           &nbsp; /blog/\${esc(p.slug)} &nbsp;·&nbsp; \${when(p.published_at||p.updated_at)}</p>
      </div>
      <div class="row-acts">
        \${p.status==='published'?\`<a class="btn btn-g" href="/blog/\${esc(p.slug)}" target="_blank" rel="noopener">View</a>\`:''}
        <button class="btn btn-g" onclick="openEditor(\${p.id})">Edit</button>
      </div>
    </div>\`).join('');
}
$('filters').onclick=(e)=>{const b=e.target.closest('button');if(!b)return;
  filter=b.dataset.f;[...$('filters').children].forEach(x=>x.classList.toggle('on',x===b));draw();};

${'/* ── editor ── */'}
window.openEditor=async function(id){
  cur=id?null:{id:null,status:'draft'};
  if(id){ try{ cur=(await api('posts/'+id)).post; }catch(e){ return toast(e.message,true); } }
  $('title').value=cur.title||''; $('slug').value=cur.slug||'';
  $('body').innerHTML=cur.body_html||'';
  $('excerpt').value=cur.excerpt||''; $('metaTitle').value=cur.meta_title||'';
  $('metaDesc').value=cur.meta_desc||''; $('tags').value=(cur.tags||[]).join(', ');
  $('coverAlt').value=cur.cover_alt||''; setCover(cur.cover_url||'');
  setStatus(cur.status||'draft');
  $('edTitle').textContent=id?'Edit post':'New post';
  $('edSub').textContent=id?('Last saved '+when(cur.updated_at)):'Not saved yet';
  $('saved').textContent=$('edSub').textContent;
  $('del').classList.toggle('hidden',!id);
  $('view-list').classList.add('hidden'); $('view-edit').classList.remove('hidden');
  $('bar').classList.remove('hidden');
  dirty=false; countMeta(); $('title').focus();
};
$('new').onclick=()=>openEditor();
$('back').onclick=()=>{
  if(dirty && !confirm('You have unsaved changes. Leave anyway?')) return;
  $('view-edit').classList.add('hidden'); $('bar').classList.add('hidden');
  $('view-list').classList.remove('hidden'); load();
};

function setStatus(s){
  [...$('statusRow').children].forEach(b=>b.classList.toggle('on',b.dataset.s===s));
  $('statusHint').textContent = s==='published'
    ? 'Live on the blog as soon as you save.'
    : 'Only you can see a draft.';
  $('publish').textContent = s==='published' ? 'Update' : 'Publish';
}
$('statusRow').onclick=(e)=>{const b=e.target.closest('button');if(b){setStatus(b.dataset.s);dirty=true;}};
const status=()=> [...$('statusRow').children].find(b=>b.classList.contains('on')).dataset.s;

${'/* slug follows the title until it is edited by hand */'}
let slugTouched=false;
$('slug').addEventListener('input',()=>{slugTouched=true;dirty=true;});
$('title').addEventListener('input',()=>{
  dirty=true;
  if(!slugTouched && !cur?.id){
    $('slug').value=$('title').value.toLowerCase().trim()
      .replace(/[^a-z0-9\\s-]/g,'').replace(/\\s+/g,'-').replace(/-+/g,'-').slice(0,80);
  }
});
['excerpt','metaTitle','metaDesc','tags','coverAlt'].forEach(id=>
  $(id).addEventListener('input',()=>{dirty=true;if(id==='metaDesc')countMeta();}));
function countMeta(){
  const n=$('metaDesc').value.length;$('mdCount').textContent=n;
  $('mdCount').style.color = n>160 ? 'var(--red)' : 'var(--mut)';
}

${'/* ── toolbar ── */'}
const body=$('body');
body.addEventListener('input',()=>{dirty=true;sync();});
body.addEventListener('keyup',sync); body.addEventListener('mouseup',sync);
function sync(){
  [...$('tb').querySelectorAll('button[data-c]')].forEach(b=>{
    try{ b.classList.toggle('on',document.queryCommandState(b.dataset.c)); }catch(_){ }
  });
  let blk='';
  try{ blk=(document.queryCommandValue('formatBlock')||'').toLowerCase(); }catch(_){ }
  [...$('tb').querySelectorAll('button[data-b]')].forEach(b=>
    b.classList.toggle('on', blk===b.dataset.b || (b.dataset.b==='p'&&(blk==='div'||blk===''))));
}
${'/* Keep the caret where the writer left it. preventDefault on'}
${'   mousedown stops the toolbar stealing focus; calling focus()'}
${'   afterwards would undo that and drop the caret at the start of'}
${'   the post, which silently scrambles what the next click formats.'}
${'   So focus is only restored when it genuinely went elsewhere. */'}
function keepCaret(){
  if(!body.contains(document.activeElement) && document.activeElement!==body) body.focus();
}
$('tb').addEventListener('mousedown',(e)=>{ if(e.target.closest('button')) e.preventDefault(); });
$('tb').addEventListener('click',(e)=>{
  const b=e.target.closest('button'); if(!b) return;
  keepCaret();
  if(b.dataset.c) document.execCommand(b.dataset.c,false,null);
  else if(b.dataset.b) document.execCommand('formatBlock',false,b.dataset.b);
  dirty=true; sync();
});
$('bLink').onclick=()=>{
  keepCaret();
  const sel=document.getSelection();
  const range=sel.rangeCount?sel.getRangeAt(0).cloneRange():null;
  const url=prompt('Link to where?','https://');
  if(range){ sel.removeAllRanges(); sel.addRange(range); }   // prompt() drops the selection
  if(url) document.execCommand('createLink',false,url);
  dirty=true;
};
$('bHr').onclick=()=>{ keepCaret(); document.execCommand('insertHorizontalRule'); dirty=true; };
$('bImg').onclick=()=>{ imgTarget='body'; $('coverFile').click(); };

${'/* Paste as plain text. Copying from another site otherwise drags its'}
${'   markup in; the server strips it anyway, so strip it here too and'}
${'   what you see stays what you get. */'}
body.addEventListener('paste',(e)=>{
  e.preventDefault();
  const t=(e.clipboardData||window.clipboardData).getData('text/plain');
  document.execCommand('insertText',false,t);
});
body.addEventListener('keydown',(e)=>{
  if((e.metaKey||e.ctrlKey)&&e.key==='k'){e.preventDefault();$('bLink').click();}
  if((e.metaKey||e.ctrlKey)&&e.key==='s'){e.preventDefault();save(status());}
});

${'/* ── images ── */'}
let imgTarget='cover';
$('cover').onclick=()=>{ imgTarget='cover'; $('coverFile').click(); };
$('coverClear').onclick=()=>{ setCover(''); dirty=true; };
function setCover(url){
  cover_url=url;
  $('cover').innerHTML = url ? \`<img src="\${esc(url)}" alt="">\` : 'Click to upload';
}
let cover_url='';
$('coverFile').onchange=async(e)=>{
  const f=e.target.files[0]; e.target.value='';
  if(!f) return;
  if(f.size>2_000_000) return toast('Keep images under 2 MB.',true);
  const data=await new Promise((res,rej)=>{
    const r=new FileReader(); r.onload=()=>res(r.result); r.onerror=rej; r.readAsDataURL(f);
  });
  try{
    const d=await api('media',{method:'POST',body:JSON.stringify({filename:f.name,mime:f.type,data_url:data})});
    if(imgTarget==='cover'){ setCover(d.media.data_url); }
    else { body.focus(); document.execCommand('insertImage',false,d.media.data_url); }
    dirty=true; toast('Image added');
  }catch(err){ toast(err.message,true); }
};

${'/* ── saving ── */'}
async function save(st){
  const payload={
    title:$('title').value, slug:$('slug').value, body_html:body.innerHTML,
    excerpt:$('excerpt').value, meta_title:$('metaTitle').value, meta_desc:$('metaDesc').value,
    tags:$('tags').value.split(',').map(s=>s.trim()).filter(Boolean),
    cover_url, cover_alt:$('coverAlt').value, status:st,
  };
  if(!payload.title.trim()) return toast('Give it a title first.',true);
  const btn = st==='published' ? $('publish') : $('saveDraft');
  const old = btn.innerHTML; btn.disabled=true; btn.innerHTML='<span class="spin"></span>';
  try{
    const d = cur?.id
      ? await api('posts/'+cur.id,{method:'PUT',body:JSON.stringify(payload)})
      : await api('posts',{method:'POST',body:JSON.stringify(payload)});
    cur=d.post; dirty=false;
    $('slug').value=cur.slug; setStatus(cur.status);
    $('del').classList.remove('hidden');
    const msg='Saved '+new Date().toLocaleTimeString('en-GB',{hour:'2-digit',minute:'2-digit'});
    $('saved').textContent=msg; $('edSub').textContent=msg;
    toast(st==='published'?'Published — it is live on /blog':'Draft saved');
  }catch(e){ toast(e.message,true); }
  btn.disabled=false; btn.innerHTML=old;
}
$('saveDraft').onclick=()=>save('draft');
$('publish').onclick=()=>save('published');
$('del').onclick=async()=>{
  if(!cur?.id) return;
  if(!confirm('Delete "'+(cur.title||'this post')+'"? This cannot be undone.')) return;
  try{ await api('posts/'+cur.id,{method:'DELETE'}); dirty=false; toast('Deleted'); $('back').click(); }
  catch(e){ toast(e.message,true); }
};
$('out').onclick=async()=>{ await fetch('/api/logout'); location.reload(); };

addEventListener('beforeunload',(e)=>{ if(dirty){ e.preventDefault(); e.returnValue=''; } });
load();
</script>
</body></html>`;
