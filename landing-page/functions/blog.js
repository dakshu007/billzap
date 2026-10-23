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

const SITE = 'https://billzap.app';

// netlify.toml's [[headers]] apply to files Netlify serves, not to
// what a function returns — a rendered page would otherwise go out
// with none of the site's security headers. So they are set here,
// matching the static pages.
const SECURITY = {
  'Content-Security-Policy':
    "default-src 'self'; script-src 'self' 'unsafe-inline' https://www.googletagmanager.com " +
    "https://static.cloudflareinsights.com; " +
    "style-src 'self' 'unsafe-inline'; img-src 'self' data: https://www.google-analytics.com " +
    "https://www.googletagmanager.com https://www.google.com https://*.g.doubleclick.net; " +
    "font-src 'self'; connect-src 'self' " +
    "https://www.google-analytics.com https://*.google-analytics.com " +
    "https://*.analytics.google.com https://www.googletagmanager.com " +
    // Where GA4 sends hits when Google signals is on, and Cloudflare's
    // Web Analytics beacon; see worker.js.
    "https://www.google.com https://*.g.doubleclick.net https://cloudflareinsights.com; " +
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
      FROM posts WHERE status = 'published' AND published_at <= now()
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
    SELECT * FROM posts WHERE slug = ${slug} AND status = 'published'
       AND published_at <= now()`;

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

  // Up to three others to read next: ones sharing a tag first, then
  // the newest. One query, and a post with no neighbours just shows none.
  const more = await sql`
    SELECT slug, title, excerpt, tags, published_at FROM posts
     WHERE status = 'published' AND published_at <= now() AND slug <> ${p.slug}
     ORDER BY (tags && ${p.tags || []}::text[]) DESC, published_at DESC
     LIMIT 3`;

  const url = `${SITE}/blog/${p.slug}`;
  const desc = p.meta_desc || p.excerpt || textOf(p.body_html, 160);
  const author = AUTHORS[p.author] || null;
  const authorName = author ? author.name : (p.author || 'BillZap');
  // Rich results read the post as written, before it is rearranged
  // for the page below.
  const rich = richResults(p.body_html, url);
  const { overview, rest } = takeOverview(p.body_html);
  const { html: outlined, items } = outline(rest);
  const bodyHtml = midCta(faqAccordion(outlined));
  const mins = readingTime(p.body_html);
  const keywords = [p.focus_keyword, ...(p.secondary_keywords || []), ...(p.tags || [])]
    .filter(Boolean);

  const post = {
    '@type': 'BlogPosting',
    '@id': `${url}#post`,
    headline: p.title,
    description: desc,
    url,
    datePublished: iso(p.published_at),
    dateModified: iso(p.updated_at),
    author: author
      ? { '@type': 'Person', '@id': `${SITE}/#${author.id}`, name: author.name,
          jobTitle: author.role, url: author.links[0].href,
          sameAs: author.links.map((l) => l.href) }
      : { '@type': 'Person', name: authorName },
    publisher: { '@id': `${SITE}/#org` },
    mainEntityOfPage: url,
    wordCount: textOf(p.body_html).split(/\s+/).filter(Boolean).length,
    timeRequired: `PT${mins}M`,
    ...(p.cover_url ? { image: abs(p.cover_url) } : {}),
    keywords: keywords.join(', '),
  };
  const ld = { '@context': 'https://schema.org', '@graph': [post, ...rich] };

  const toc = items.length > 2 ? `<ol>${items.map((it) => `
                <li><a href="#${it.id}">${esc(it.text)}</a></li>`).join('')}
              </ol>` : '';
  const tag = (p.tags && p.tags[0]) || 'Guide';

  return page(200, shell({
    title: p.meta_title || `${p.title} | BillZap`,
    desc,
    canonical: url,
    keywords: keywords.join(', '),
    image: p.cover_url ? abs(p.cover_url) : `${SITE}/assets/og.png`,
    ogType: 'article',
    ld,
    body: `
      <article class="bpage">
        <div class="wrap">
          <a class="bback" href="/blog">${ICON.back} All posts</a>

          <header class="bhead">
            <p class="bpill">${esc(tag)}</p>
            <h1>${esc(p.title)}</h1>
            ${p.excerpt ? `<p class="bsub">${esc(p.excerpt)}</p>` : ''}
            <div class="bby">
              ${avatar(authorName, 'sm')}
              <div class="bby-t">
                <strong>${esc(authorName)}</strong>
                <span><time datetime="${iso(p.published_at)}">${human(p.published_at)}</time> · ${mins} min read</span>
              </div>
            </div>
            <div class="bacts">
              <a class="btn btn-primary" href="${PLAY}" rel="noopener">Download free <span class="chip">${ICON.arrow}</span></a>
              ${share(url, p.title, 'top')}
            </div>
          </header>

          ${p.cover_url ? `<figure class="bcover">
            <img src="${esc(p.cover_url)}" alt="${esc(p.cover_alt || '')}" decoding="async">
          </figure>` : ''}

          <div class="blayout">
            <div class="bmain">
              <section class="bai" aria-labelledby="bai-h">
                <div class="bai-top">
                  <span class="bai-ico">${ICON.sparkle}</span>
                  <h2 id="bai-h">AI overview</h2>
                  <span class="bai-tag">Quick answer</span>
                </div>
                <div class="bai-body">${overview || `<p>${esc(desc)}</p>`}</div>
                <div class="bai-ask">
                  <p>Summarize with AI</p>
                  <div class="bai-btns">${askAi(url, p.title)}</div>
                </div>
              </section>

              ${toc ? `<details class="btoc-m">
                <summary>${ICON.list} On this page <span>${items.length} sections</span></summary>
                ${toc}
              </details>` : ''}

              <div class="bcard">
                <div class="prose bprose">${bodyHtml}</div>

                <div class="bend">
                  <span class="bend-ico">${ICON.zap}</span>
                  <h2>Make your next GST bill in 30 seconds</h2>
                  <p>BillZap is free, works with no internet and needs no sign-up.</p>
                  <a class="btn btn-primary btn-lg" href="${PLAY}" rel="noopener">Download free on Google Play <span class="chip">${ICON.arrow}</span></a>
                </div>

                <div class="bshare">
                  <p>Share this guide</p>
                  ${share(url, p.title, 'bottom')}
                </div>

                ${author ? `<aside class="bauthor" aria-label="About the author">
                  ${avatar(author.name, 'lg')}
                  <div>
                    <p class="bauthor-k">Written by</p>
                    <p class="bauthor-n">${esc(author.name)}</p>
                    <p class="bauthor-r">${esc(author.role)}</p>
                    <p class="bauthor-b">${esc(author.bio)}</p>
                    <p class="bauthor-l">${author.links.map((l) =>
                      `<a href="${l.href}" rel="noopener me" target="_blank">${esc(l.label)}</a>`).join('')}</p>
                  </div>
                </aside>` : ''}
              </div>
            </div>

            <aside class="bside">
              ${toc ? `<nav class="btoc" aria-label="On this page">
                <p class="btoc-h">On this page</p>
                ${toc}
              </nav>` : ''}
              <div class="bmini">
                <p class="bmini-h">BillZap</p>
                <p>Free GST billing app. Offline, no sign-up, UPI QR on every bill.</p>
                <a class="btn btn-primary" href="${PLAY}" rel="noopener">Download free <span class="chip">${ICON.arrow}</span></a>
              </div>
            </aside>
          </div>

          ${more.length ? `<section class="bmore" aria-labelledby="bmore-h">
            <div class="bmore-top">
              <h2 id="bmore-h">Keep reading</h2>
              <a href="/blog">All posts ${ICON.arrow}</a>
            </div>
            <div class="bmore-grid">${more.map((m) => `
              <a class="bmore-c" href="/blog/${esc(m.slug)}">
                ${m.tags?.length ? `<span class="bmore-t">${esc(m.tags[0])}</span>` : ''}
                <span class="bmore-h">${esc(m.title)}</span>
                <span class="bmore-e">${esc(m.excerpt)}</span>
                <span class="bmore-go">Read ${ICON.arrow}</span>
              </a>`).join('')}
            </div>
          </section>` : ''}
        </div>
      </article>`,
  }));
}

const PLAY = 'https://play.google.com/store/apps/details?id=com.billzap.app';

// The people who write here. Keyed by the name in a post's author
// field, so a post by anyone else still renders, just without a bio.
const AUTHORS = {
  'Dakshesh B': {
    id: 'dakshesh-b',
    name: 'Dakshesh B',
    role: 'Full-stack developer · Builder of BillZap',
    bio: 'Dakshesh B is a full-stack developer who designed and built BillZap, the free '
      + 'offline GST billing app on Google Play, after watching small shops lose time to '
      + 'paper bills and confusing software. These guides explain GST, invoicing and '
      + 'running a shop in plain language, checked against CBIC and GST portal sources.',
    links: [
      { label: 'LinkedIn', href: 'https://www.linkedin.com/in/daksheshb' },
      { label: 'GitHub', href: 'https://github.com/dakshu007' },
      { label: 'Website', href: 'https://dakshesh.co.in' },
    ],
  },
};

function avatar(name, size) {
  const ini = String(name).split(/\s+/).map((w) => w[0] || '').join('').slice(0, 2).toUpperCase();
  return `<span class="bav bav-${size}" aria-hidden="true">${esc(ini)}</span>`;
}

/** Share links. Plain URLs, so they work with scripts off; the copy
 *  button is the one thing that needs JavaScript. */
function share(url, title, where) {
  const u = encodeURIComponent(url);
  const t = encodeURIComponent(title);
  return `<div class="bsh bsh-${where}">
    <a class="bsh-b" href="https://www.linkedin.com/sharing/share-offsite/?url=${u}" target="_blank" rel="noopener" aria-label="Share on LinkedIn">${ICON.linkedin}<span>LinkedIn</span></a>
    <a class="bsh-b" href="https://twitter.com/intent/tweet?url=${u}&amp;text=${t}" target="_blank" rel="noopener" aria-label="Share on X">${ICON.x}<span>X</span></a>
    <a class="bsh-b" href="https://wa.me/?text=${t}%20${u}" target="_blank" rel="noopener" aria-label="Share on WhatsApp">${ICON.whatsapp}<span>WhatsApp</span></a>
    <button class="bsh-b" type="button" data-copy="${esc(url)}" aria-label="Copy link">${ICON.link}<span>Copy link</span></button>
  </div>`;
}

/** "Summarize with AI": each assistant opened with the post's URL and
 *  a ready-made prompt. Nothing is sent anywhere until the reader
 *  clicks. */
function askAi(url, title) {
  const prompt = encodeURIComponent(
    `Summarize this article from BillZap in simple bullet points, with the key takeaways `
    + `for a small business owner in India: ${url}`);
  const list = [
    ['ChatGPT', `https://chatgpt.com/?q=${prompt}`],
    ['Perplexity', `https://www.perplexity.ai/search/new?q=${prompt}`],
    ['Claude', `https://claude.ai/new?q=${prompt}`],
    ['Google AI', `https://www.google.com/search?udm=50&q=${prompt}`],
    ['Grok', `https://grok.com/?q=${prompt}`],
  ];
  return list.map(([n, h]) =>
    `<a href="${h}" target="_blank" rel="noopener nofollow" aria-label="Summarize ${esc(title)} with ${n}">${n}</a>`).join('');
}

/** Lift the post's "Quick answer" section out of the body, to be shown
 *  as the AI overview card at the top. Posts without one keep their
 *  body untouched and the card falls back to the description. */
function takeOverview(html) {
  const src = String(html || '');
  const m = src.match(/<h2[^>]*>\s*(?:quick|short) answer\s*<\/h2>/i);
  if (!m) return { overview: '', rest: src };
  const start = m.index + m[0].length;
  const next = src.slice(start).search(/<h2[\s>]/i);
  const end = next < 0 ? src.length : start + next;
  return { overview: src.slice(start, end).trim(),
           rest: src.slice(0, m.index) + src.slice(end) };
}

/** Turn the FAQ section's question headings into an accordion. The
 *  FAQPage markup is read from the original body, so it is unaffected. */
function faqAccordion(html) {
  const src = String(html || '');
  const h2s = [...src.matchAll(/<h2[^>]*>([\s\S]*?)<\/h2>/gi)];
  const faq = h2s.find((m) => /faq|questions/i.test(textOf(m[1])));
  if (!faq) return src;
  const start = faq.index + faq[0].length;
  const next = h2s.find((m) => m.index > faq.index);
  const end = next ? next.index : src.length;
  const block = src.slice(start, end);
  const parts = block.split(/<h3[^>]*>/i);
  const lead = parts.shift();
  const qa = parts.map((part, i) => {
    const [q, ...rest] = part.split(/<\/h3>/i);
    return `<details class="bfaq"${i === 0 ? ' open' : ''}><summary>${q}<span class="bfaq-i" aria-hidden="true"></span></summary>`
      + `<div class="bfaq-a">${rest.join('</h3>')}</div></details>`;
  }).join('');
  return src.slice(0, start) + lead + `<div class="bfaqs">${qa}</div>` + src.slice(end);
}

/** A download card halfway through the article, placed before a
 *  section heading so it never splits a paragraph or a table. */
function midCta(html) {
  const src = String(html || '');
  const h2s = [...src.matchAll(/<h2[\s>]/gi)].map((m) => m.index);
  if (h2s.length < 4) return src;
  const at = h2s[Math.floor(h2s.length / 2)];
  const card = `<aside class="bmid">
      <span class="bmid-ico">${ICON.zap}</span>
      <div><p class="bmid-h">Bill faster with BillZap</p>
        <p>Free GST billing app: CGST, SGST and IGST worked out for you, UPI QR on every bill, works offline.</p></div>
      <a class="btn btn-primary" href="${PLAY}" rel="noopener">Download free <span class="chip">${ICON.arrow}</span></a>
    </aside>`;
  return src.slice(0, at) + card + src.slice(at);
}

// Posts are created without a deploy, so they cannot be in the static
// sitemap.xml. This one is generated from the table on request and
// referenced from robots.txt.
async function renderSitemap() {
  const rows = await sql`
    SELECT slug, updated_at FROM posts
     WHERE status = 'published' AND published_at <= now()
     ORDER BY published_at DESC LIMIT 5000`;
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
     WHERE status = 'published' AND published_at <= now()
     ORDER BY published_at DESC LIMIT 40`;
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
      // The contents list is sections only. Sub-headings, and the
      // questions under the FAQ, still get anchors but no entry.
      if (tag.toLowerCase() === 'h2') items.push({ id, text, level: 2 });
      return `<${tag} id="${id}">${inner}</${tag}>`;
    });
  return { html: out, items };
}

/** FAQPage and ItemList, read off the post's own headings.
 *
 * A post earns rich results by structure, not by extra fields in the
 * editor: an h2 whose text contains "FAQ" or "questions" makes every h3
 * under it a question, answered by whatever follows it; and h3s written
 * "1. Name", "2. Name"… make a ranked list. The markup is only ever a
 * reading of what the page already says, which is the rule Google
 * holds rich results to.
 */
function richResults(html, url) {
  const out = [];
  const src = String(html || '');
  const h2s = [...src.matchAll(/<h2[^>]*>([\s\S]*?)<\/h2>/gi)];
  const faq = h2s.find((m) => /faq|questions/i.test(textOf(m[1])));
  if (faq) {
    const start = faq.index + faq[0].length;
    const next = h2s.find((m) => m.index > faq.index);
    const block = src.slice(start, next ? next.index : undefined);
    const parts = block.split(/<h3[^>]*>/i).slice(1);
    const qa = parts.map((part) => {
      const [q, ...rest] = part.split(/<\/h3>/i);
      return { q: textOf(q), a: textOf(rest.join(' ')) };
    }).filter((x) => x.q && x.a);
    if (qa.length) out.push({
      '@type': 'FAQPage', '@id': `${url}#faq`,
      mainEntity: qa.map(({ q, a }) => ({
        '@type': 'Question', name: q,
        acceptedAnswer: { '@type': 'Answer', text: a } })),
    });
  }
  const ranked = [...src.matchAll(/<h3[^>]*>\s*(\d+)\.\s*([\s\S]*?)<\/h3>/gi)]
    .map((m) => ({ n: +m[1], name: textOf(m[2]).replace(/\s*\([^)]*\)\s*$/, '') }));
  if (ranked.length >= 3 && ranked.every((r, i) => r.n === i + 1)) out.push({
    '@type': 'ItemList', '@id': `${url}#list`,
    itemListOrder: 'https://schema.org/ItemListOrderAscending',
    numberOfItems: ranked.length,
    itemListElement: ranked.map((r) => ({ '@type': 'ListItem', position: r.n, name: r.name })),
  });
  return out;
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

  /* Copy link: the share bar's one button that needs script. */
  d.querySelectorAll('[data-copy]').forEach(function(b){
    b.addEventListener('click',function(){
      var u=b.getAttribute('data-copy'), lab=b.querySelector('span');
      var done=function(){ if(lab){var o=lab.textContent;lab.textContent='Copied';
        b.classList.add('ok');setTimeout(function(){lab.textContent=o;b.classList.remove('ok');},1800);} };
      if(navigator.clipboard&&navigator.clipboard.writeText){navigator.clipboard.writeText(u).then(done,function(){prompt('Copy this link',u);});}
      else{prompt('Copy this link',u);}
    });
  });
  /* The phone contents menu folds itself away once a section is picked. */
  var tm=d.querySelector('.btoc-m');
  if(tm){tm.addEventListener('click',function(e){if(e.target.closest('a'))tm.open=false;});}

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

const svg = (body, fill = false) => `<svg viewBox="0 0 24 24" ${fill
  ? 'fill="currentColor"' : 'fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"'} aria-hidden="true">${body}</svg>`;
const ICON = {
  back: svg('<path d="m12 19-7-7 7-7"/><path d="M19 12H5"/>'),
  arrow: svg('<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>'),
  sparkle: svg('<path d="M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0z" /><path d="M20 3v4" /><path d="M22 5h-4" /><path d="M4 17v2" /><path d="M5 18H3" />'),
  list: svg('<path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01"/>'),
  zap: svg('<path d="M4 14a1 1 0 0 1-.78-1.63l9.9-10.2a.5.5 0 0 1 .86.46l-1.92 6.02A1 1 0 0 0 13 10h7a1 1 0 0 1 .78 1.63l-9.9 10.2a.5.5 0 0 1-.86-.46l1.92-6.02A1 1 0 0 0 11 14z"/>'),
  link: svg('<path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>'),
  linkedin: svg('<path d="M20.45 20.45h-3.56v-5.57c0-1.33-.02-3.04-1.85-3.04-1.85 0-2.14 1.45-2.14 2.94v5.67H9.35V9h3.41v1.56h.05c.48-.9 1.64-1.85 3.37-1.85 3.6 0 4.27 2.37 4.27 5.46zM5.34 7.43a2.06 2.06 0 1 1 0-4.13 2.06 2.06 0 0 1 0 4.13M7.12 20.45H3.56V9h3.56zM22.22 0H1.77C.79 0 0 .77 0 1.73v20.54C0 23.23.79 24 1.77 24h20.45c.98 0 1.78-.77 1.78-1.73V1.73C24 .77 23.2 0 22.22 0"/>', true),
  x: svg('<path d="M18.9 1.15h3.68l-8.04 9.19L24 22.85h-7.4l-5.8-7.58-6.64 7.58H.48l8.6-9.83L0 1.15h7.59l5.24 6.93zm-1.29 19.5h2.04L6.48 3.24H4.3z"/>', true),
  whatsapp: svg('<path d="M12 2a10 10 0 0 0-8.6 15.1L2 22l5-1.3A10 10 0 1 0 12 2m0 18.2a8.2 8.2 0 0 1-4.2-1.2l-.3-.2-3 .8.8-2.9-.2-.3A8.2 8.2 0 1 1 12 20.2m4.5-6.1c-.2-.1-1.5-.7-1.7-.8s-.4-.1-.6.1-.7.8-.8 1-.3.2-.6.1a6.7 6.7 0 0 1-3.3-2.9c-.2-.4.2-.4.7-1.3.1-.2 0-.3 0-.4l-.8-1.8c-.2-.5-.4-.4-.6-.4h-.5a.9.9 0 0 0-.7.3 2.8 2.8 0 0 0-.9 2.1 4.9 4.9 0 0 0 1 2.6 11.2 11.2 0 0 0 4.3 3.8c1.6.7 2.2.7 3 .6a2.6 2.6 0 0 0 1.7-1.2 2.1 2.1 0 0 0 .1-1.2c0-.1-.2-.2-.4-.3"/>', true),
};

const abs = (u) => (/^https?:\/\//i.test(u) ? u : `${SITE}${u.startsWith('/') ? '' : '/'}${u}`);
const iso = (d) => (d ? new Date(d).toISOString() : '');
const human = (d) => (d
  ? new Date(d).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })
  : '');
