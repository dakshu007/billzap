// The public blog: /blog and /blog/<slug>.
//
// Rendered here rather than built into the static site, because the
// brief is that a post appears the moment it is published — a static
// build would need a redeploy first. It returns real HTML, not a
// shell that fetches JSON, so a crawler and a reader see the same
// thing on the first response.
import { sql, ready, redact } from './lib/db.js';
import { CSS, header, footer, head } from './lib/shell.js';
import { esc, textOf } from './lib/html.js';

const SITE = 'https://billzap.netlify.app';

// netlify.toml's [[headers]] apply to files Netlify serves, not to
// what a function returns — a rendered page would otherwise go out
// with none of the site's security headers. So they are set here,
// matching the static pages.
const SECURITY = {
  'Content-Security-Policy':
    "default-src 'self'; script-src 'self' 'unsafe-inline' https://www.googletagmanager.com; " +
    "style-src 'self' 'unsafe-inline'; img-src 'self' data: https://www.google-analytics.com " +
    "https://www.googletagmanager.com; font-src 'self'; connect-src 'self' " +
    "https://www.google-analytics.com https://*.google-analytics.com " +
    "https://*.analytics.google.com https://www.googletagmanager.com; " +
    "form-action 'self'; frame-ancestors 'self'; base-uri 'self'; object-src 'none'; " +
    'upgrade-insecure-requests',
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'SAMEORIGIN',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
};

const page = (status, body, extra = {}) => ({
  statusCode: status,
  headers: {
    'Content-Type': 'text/html; charset=utf-8',
    // Short public cache: a new post should show up quickly, but a
    // burst of readers should not each wake the database.
    'Cache-Control': 'public, max-age=0, s-maxage=60, must-revalidate',
    ...SECURITY,
    ...extra,
  },
  body,
});

export async function handler(event) {
  const path = (event.path || '/blog').replace(/\/+$/, '') || '/blog';
  const slug = path.startsWith('/blog/') ? path.slice(6) : null;

  try {
    await ready();
    if (path.startsWith('/media/')) return await serveMedia(path.slice(7));
    if (path === '/sitemap-blog.xml') return await renderSitemap();
    if (path === '/blog/feed.xml' || path === '/blog/rss.xml') return await renderFeed();
    return slug ? await renderPost(slug) : await renderIndex();
  } catch (err) {
    console.error('blog error', err);
    // The reader gets a plain apology. The cause goes in a comment,
    // scrubbed of host, user and password — without it a failure here
    // is invisible from outside, and outside is the only place this
    // can be observed.
    return page(500, shell({
      title: 'Blog — BillZap',
      desc: 'The BillZap blog.',
      canonical: `${SITE}/blog`,
      robots: 'noindex,follow',
      body: `<section class="legal"><div class="wrap"><div class="legal-head">
               <h1>The blog is having a moment</h1>
               <p class="lead">It could not be loaded just now. Please try again shortly.</p>
             </div></div></section>
             <!-- diag: ${esc(redact(err))} -->
             <!-- env: ${['DATABASE_URL','ADMIN_PATH','ADMIN_PASSWORD','SESSION_SECRET']
                   .map((k) => `${k}=${process.env[k] ? 'set' : 'MISSING'}`).join(' ')} -->`,
    }));
  }
}

async function renderIndex() {
  const posts = await sql`
    SELECT slug, title, excerpt, cover_url, cover_alt, tags, published_at
      FROM posts WHERE status = 'published'
     ORDER BY published_at DESC LIMIT 60`;

  const cards = posts.map((p) => `
    <article class="bpost rv">
      ${p.cover_url ? `<a class="bpost-img" href="/blog/${esc(p.slug)}">
        <img src="${esc(p.cover_url)}" alt="${esc(p.cover_alt || '')}" loading="lazy" decoding="async">
      </a>` : ''}
      <div class="bpost-body">
        ${p.tags?.length ? `<p class="bpost-tags">${p.tags.map((t) => esc(t)).join(' · ')}</p>` : ''}
        <h2><a href="/blog/${esc(p.slug)}">${esc(p.title)}</a></h2>
        <p>${esc(p.excerpt)}</p>
        <p class="bpost-meta"><time datetime="${iso(p.published_at)}">${human(p.published_at)}</time></p>
      </div>
    </article>`).join('\n');

  const empty = `
    <div class="bempty">
      <h2>Nothing published yet</h2>
      <p>Guides on GST billing, invoicing and running a shop are on the way.</p>
      <p><a class="btn btn-ghost" href="/">Back to BillZap</a></p>
    </div>`;

  const ld = {
    '@context': 'https://schema.org',
    '@type': 'Blog',
    '@id': `${SITE}/blog#blog`,
    name: 'The BillZap Blog',
    url: `${SITE}/blog`,
    description: 'Guides on GST billing, invoicing and running a small shop in India.',
    publisher: { '@id': `${SITE}/#org` },
    blogPost: posts.map((p) => ({
      '@type': 'BlogPosting',
      headline: p.title,
      url: `${SITE}/blog/${p.slug}`,
      datePublished: iso(p.published_at),
      description: p.excerpt,
    })),
  };

  return page(200, shell({
    title: 'Blog — GST billing and invoicing guides | BillZap',
    desc: 'Practical guides on GST billing, tax invoices, UPI payments and running a small shop in India — from the team behind BillZap.',
    canonical: `${SITE}/blog`,
    ld,
    body: `
      <section class="legal">
        <div class="wrap">
          <div class="legal-head">
            <p class="eyebrow">Blog</p>
            <h1>Running a shop, written down.</h1>
            <p class="lead">
              GST, invoices, getting paid, and the small operational things
              nobody explains — from the people who build BillZap.
            </p>
          </div>
          <div class="blist">${posts.length ? cards : empty}</div>
        </div>
      </section>`,
  }));
}

async function renderPost(slugRaw) {
  const slug = decodeURIComponent(slugRaw).replace(/[^a-z0-9-]/gi, '');
  const [p] = await sql`
    SELECT * FROM posts WHERE slug = ${slug} AND status = 'published'`;

  if (!p) {
    return page(404, shell({
      title: 'Not found — BillZap',
      desc: 'That post does not exist.',
      canonical: `${SITE}/blog`,
      robots: 'noindex,follow',
      body: `<section class="legal"><div class="wrap"><div class="legal-head">
               <h1>That post is not here</h1>
               <p class="lead">It may have been renamed or never published.</p>
               <p style="margin-top:26px"><a class="btn btn-ghost" href="/blog">See all posts</a></p>
             </div></div></section>`,
    }));
  }

  const desc = p.meta_desc || p.excerpt || textOf(p.body_html, 160);
  const { html: bodyHtml, items } = outline(p.body_html);
  const mins = readingTime(p.body_html);
  const keywords = [p.focus_keyword, ...(p.secondary_keywords || []), ...(p.tags || [])]
    .filter(Boolean);

  const ld = {
    '@context': 'https://schema.org',
    '@type': 'BlogPosting',
    '@id': `${SITE}/blog/${p.slug}#post`,
    headline: p.title,
    description: desc,
    url: `${SITE}/blog/${p.slug}`,
    datePublished: iso(p.published_at),
    dateModified: iso(p.updated_at),
    author: { '@type': 'Person', name: p.author || 'BillZap' },
    publisher: { '@id': `${SITE}/#org` },
    mainEntityOfPage: `${SITE}/blog/${p.slug}`,
    wordCount: textOf(p.body_html).split(/\s+/).filter(Boolean).length,
    timeRequired: `PT${mins}M`,
    ...(p.cover_url ? { image: abs(p.cover_url) } : {}),
    keywords: keywords.join(', '),
  };

  return page(200, shell({
    title: p.meta_title || `${p.title} | BillZap`,
    desc,
    canonical: `${SITE}/blog/${p.slug}`,
    keywords: [p.focus_keyword, ...(p.secondary_keywords || []), ...(p.tags || [])]
      .filter(Boolean).join(', '),
    image: p.cover_url ? abs(p.cover_url) : `${SITE}/assets/og.png`,
    ogType: 'article',
    ld,
    body: `
      <article class="bpage">
        <div class="wrap">
          <a class="bback" href="/blog">${ICON_BACK} All posts</a>

          <header class="bhead">
            <p class="bpill">Blog</p>
            <h1>${esc(p.title)}</h1>
            <p class="bby">
              By <strong>${esc(p.author || 'BillZap')}</strong>
              · <time datetime="${iso(p.published_at)}">${human(p.published_at)}</time>
              · ${mins} min read
            </p>
            ${keywords.length ? `<ul class="bkw">${keywords.slice(0, 6)
              .map((k) => `<li>${esc(k)}</li>`).join('')}</ul>` : ''}
            <div class="bcta">
              <a class="btn btn-primary" href="/#download">Download BillZap free</a>
              <p>Free forever · no sign-up · works offline</p>
            </div>
          </header>

          ${p.cover_url ? `<figure class="bcover">
            <img src="${esc(p.cover_url)}" alt="${esc(p.cover_alt || '')}" decoding="async">
          </figure>` : ''}

          <div class="blayout">
            <div class="bcard">
              ${p.excerpt ? `<p class="blede">${esc(p.excerpt)}</p>` : ''}
              <div class="prose bprose">${bodyHtml}</div>
              <div class="bend">
                <h2>Billing taking longer than it should?</h2>
                <p>
                  BillZap makes a GST invoice in about 30 seconds, works with
                  no signal, and costs nothing.
                </p>
                <a class="btn btn-primary" href="/#download">Get it for Android</a>
              </div>
            </div>

            ${items.length > 2 ? `<aside class="btoc">
              <p class="btoc-h">Table of contents</p>
              <ol>${items.map((it) => `
                <li class="lvl${it.level}"><a href="#${it.id}">${esc(it.text)}</a></li>`).join('')}
              </ol>
            </aside>` : ''}
          </div>

          <p class="bfoot"><a class="btn btn-ghost" href="/blog">${ICON_BACK} All posts</a></p>
        </div>
      </article>`,
  }));
}


// Posts are created without a deploy, so they cannot be in the static
// sitemap.xml. This one is generated from the table on request and
// referenced from robots.txt.
async function renderSitemap() {
  const rows = await sql`
    SELECT slug, updated_at FROM posts
     WHERE status = 'published' ORDER BY published_at DESC LIMIT 5000`;
  const urls = rows.map((r) => `  <url>
    <loc>${SITE}/blog/${esc(r.slug)}</loc>
    <lastmod>${iso(r.updated_at).slice(0, 10)}</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.7</priority>
  </url>`).join('\n');
  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/xml; charset=utf-8',
               'Cache-Control': 'public, max-age=0, s-maxage=300' },
    body: `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls}
</urlset>`,
  };
}

// RSS, because people who follow a niche trade blog still use readers,
// and it costs one query.
async function renderFeed() {
  const rows = await sql`
    SELECT slug, title, excerpt, published_at FROM posts
     WHERE status = 'published' ORDER BY published_at DESC LIMIT 40`;
  const items = rows.map((r) => `  <item>
    <title>${esc(r.title)}</title>
    <link>${SITE}/blog/${esc(r.slug)}</link>
    <guid isPermaLink="true">${SITE}/blog/${esc(r.slug)}</guid>
    <description>${esc(r.excerpt)}</description>
    <pubDate>${r.published_at ? new Date(r.published_at).toUTCString() : ''}</pubDate>
  </item>`).join('\n');
  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/rss+xml; charset=utf-8',
               'Cache-Control': 'public, max-age=0, s-maxage=300' },
    body: `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"><channel>
  <title>The BillZap Blog</title>
  <link>${SITE}/blog</link>
  <description>Guides on GST billing, invoicing and running a small shop in India.</description>
  <language>en</language>
${items}
</channel></rss>`,
  };
}

/** An uploaded image, as its own response.
 *
 * The whole reason this route exists: a function may return at most
 * 6 MB, and an image inlined into a post as a data URL counted against
 * that same budget — one photo could take the entire page over the
 * limit and crash it. Served separately, each image gets its own
 * response and the HTML stays small.
 *
 * Content-addressed by row id and immutable, so a reader fetches each
 * one once.
 */
async function serveMedia(idRaw) {
  const id = Number(String(idRaw).replace(/[^0-9]/g, ''));
  if (!id) return { statusCode: 404, body: 'Not found' };

  const [m] = await sql`SELECT mime, data_url FROM media WHERE id = ${id}`;
  if (!m) return { statusCode: 404, body: 'Not found' };

  const comma = m.data_url.indexOf(',');
  return {
    statusCode: 200,
    headers: {
      'Content-Type': m.mime || 'image/png',
      'Cache-Control': 'public, max-age=31536000, immutable',
      'X-Content-Type-Options': 'nosniff',
    },
    body: m.data_url.slice(comma + 1),
    isBase64Encoded: true,
  };
}

/** Give every heading an anchor and collect them into a contents list.
 *
 * Done at render time rather than on save: the sanitiser strips id
 * attributes (an author has no business setting them), and anchors
 * generated here stay correct if a heading is later edited.
 */
function outline(html) {
  const items = [];
  const used = new Set();
  const out = String(html || '').replace(
    /<(h[23])(\s[^>]*)?>([\s\S]*?)<\/\1>/gi,
    (m, tag, attrs, inner) => {
      const text = textOf(inner);
      if (!text) return m;
      let id = text.toLowerCase().replace(/[^a-z0-9\s-]/g, '')
        .replace(/\s+/g, '-').replace(/-+/g, '-').replace(/^-|-$/g, '').slice(0, 60) || 'section';
      let n = 1;
      while (used.has(id)) id = `${id}-${++n}`;
      used.add(id);
      items.push({ id, text, level: tag.toLowerCase() === 'h2' ? 2 : 3 });
      return `<${tag} id="${id}">${inner}</${tag}>`;
    });
  return { html: out, items };
}

/** Minutes to read, at the 200 words a minute everybody uses. */
function readingTime(html) {
  const words = textOf(html).split(/\s+/).filter(Boolean).length;
  return Math.max(1, Math.round(words / 200));
}

function shell({ title, desc, canonical, body, ld, image, keywords,
                 ogType = 'website',
                 robots = 'index,follow,max-image-preview:large,max-snippet:-1' }) {
  return `<!doctype html>
<html lang="en">
${head({ title, desc, canonical, image, ogType, robots, keywords, css: CSS, ld })}
<body>
${header({ base: '/' })}
<main id="main">
${body}
</main>
${footer({ base: '/' })}
<script>
(function(){
  var d=document,r=d.documentElement;
  if('IntersectionObserver' in window && !matchMedia('(prefers-reduced-motion: reduce)').matches){
    r.className+=' js';
    var io=new IntersectionObserver(function(es){es.forEach(function(e){
      if(e.isIntersecting){e.target.classList.add('in');io.unobserve(e.target);}});},
      {rootMargin:'0px 0px -8% 0px',threshold:0.06});
    d.querySelectorAll('.rv').forEach(function(n){io.observe(n);});
  }
  var h=d.getElementById('hdr');
  if(h){var s=function(){h.classList.toggle('stuck',window.scrollY>8);};
    addEventListener('scroll',s,{passive:true});s();}
  var y=d.getElementById('yr'); if(y){y.textContent=new Date().getFullYear();}

  /* Light up the contents entry for whatever is on screen. Reading
     position, not click state — somebody who scrolled here without
     touching the list should still see where they are. */
  var toc=d.querySelector('.btoc');
  if(toc && 'IntersectionObserver' in window){
    var links={};
    toc.querySelectorAll('a[href^="#"]').forEach(function(a){
      links[decodeURIComponent(a.getAttribute('href').slice(1))]=a;
    });
    var seen=[];
    var spy=new IntersectionObserver(function(es){
      es.forEach(function(e){
        var id=e.target.id, i=seen.indexOf(id);
        if(e.isIntersecting){ if(i<0) seen.push(id); }
        else if(i>-1){ seen.splice(i,1); }
      });
      var current=seen[0];
      for(var k in links) links[k].classList.toggle('on', k===current);
      if(current && links[current]){
        var a=links[current], box=toc.getBoundingClientRect(), r=a.getBoundingClientRect();
        if(r.top<box.top||r.bottom>box.bottom) a.scrollIntoView({block:'nearest'});
      }
    },{rootMargin:'-88px 0px -68% 0px'});
    d.querySelectorAll('.bprose h2[id], .bprose h3[id]').forEach(function(h){spy.observe(h);});
  }
})();
</script>
</body>
</html>`;
}

const ICON_BACK = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" '
  + 'stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">'
  + '<path d="m12 19-7-7 7-7"/><path d="M19 12H5"/></svg>';

const abs = (u) => (/^https?:\/\//i.test(u) ? u : `${SITE}${u.startsWith('/') ? '' : '/'}${u}`);
const iso = (d) => (d ? new Date(d).toISOString() : '');
const human = (d) => (d
  ? new Date(d).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })
  : '');
