// Everything the studio talks to. One function, routed on the path
// after /api/, because a handful of small handlers in separate files
// would each pay their own cold start.
import { sql, ready } from './lib/db.js';
import { isAuthed, issueCookie, clearCookie, verifyPassword } from './lib/auth.js';
import { sanitize, textOf, slugify, esc } from './lib/html.js';
import { issueTryCookie, clearTryCookie } from './lib/try-session.js';
import crypto from 'node:crypto';

const json = (status, body, extra = {}) => ({
  statusCode: status,
  headers: { 'Content-Type': 'application/json; charset=utf-8',
             'Cache-Control': 'no-store', ...extra },
  body: JSON.stringify(body),
});

export async function handler(event) {
  const route = (event.path || '').replace(/^.*\/api\/?/, '').replace(/\/+$/, '');
  const method = event.httpMethod;
  let payload = {};
  if (event.body) { try { payload = JSON.parse(event.body); } catch { /* form posts */ } }

  try {
    // ── Unauthenticated ──────────────────────────────────────────
    if (route === 'login' && method === 'POST') {
      // A wrong password costs a second. Nothing here is worth
      // letting somebody grind through a wordlist at full speed, and
      // the real owner types a password twice a week.
      await new Promise((r) => setTimeout(r, 900));
      const ok = verifyPassword(String(payload.password || ''),
                                process.env.ADMIN_PASSWORD || '');
      if (!ok) return json(401, { error: 'Wrong password.' });
      return json(200, { ok: true }, { 'Set-Cookie': issueCookie() });
    }

    if (route === 'logout') {
      return json(200, { ok: true }, { 'Set-Cookie': clearCookie() });
    }

    // ── The browser demo at /try ─────────────────────────────────
    if (route === 'try/start' && method === 'POST') return await tryStart(event, payload);
    if (route === 'try/verify' && method === 'POST') return await tryVerify(payload);
    if (route === 'try/reset' && method === 'POST') {
      return json(200, { ok: true }, { 'Set-Cookie': clearTryCookie() });
    }

    // ── Everything below needs a session ─────────────────────────
    if (!isAuthed(event.headers || {})) return json(401, { error: 'Not signed in.' });
    await ready();

    if (route === 'try/leads.csv' && method === 'GET') return await leadsCsv();

    if (route === 'posts' && method === 'GET') {
      const rows = await sql`
        SELECT id, slug, title, excerpt, status, tags, cover_url,
               created_at, updated_at, published_at
          FROM posts
         ORDER BY COALESCE(published_at, updated_at) DESC`;
      return json(200, { posts: rows });
    }

    if (route.startsWith('posts/') && method === 'GET') {
      const id = Number(route.split('/')[1]);
      const [row] = await sql`SELECT * FROM posts WHERE id = ${id}`;
      return row ? json(200, { post: row }) : json(404, { error: 'No such post.' });
    }

    if (route === 'posts' && method === 'POST') {
      const p = normalise(payload);
      const slug = await uniqueSlug(p.slug, null);
      const [row] = await sql`
        INSERT INTO posts (slug, title, excerpt, body_html, cover_url, cover_alt,
                           tags, meta_title, meta_desc, focus_keyword,
                           secondary_keywords, author, status, published_at)
        VALUES (${slug}, ${p.title}, ${p.excerpt}, ${p.body_html}, ${p.cover_url},
                ${p.cover_alt}, ${p.tags}, ${p.meta_title}, ${p.meta_desc},
                ${p.focus_keyword}, ${p.secondary_keywords}, ${p.author},
                ${p.status}, ${p.status === 'published' ? new Date() : null})
        RETURNING *`;
      return json(200, { post: row });
    }

    if (route.startsWith('posts/') && (method === 'PUT' || method === 'PATCH')) {
      const id = Number(route.split('/')[1]);
      const [current] = await sql`SELECT * FROM posts WHERE id = ${id}`;
      if (!current) return json(404, { error: 'No such post.' });
      const p = normalise(payload);
      const slug = await uniqueSlug(p.slug, id);
      // First publish stamps the date; later edits must not move it,
      // or every typo fix reorders the blog.
      const publishedAt = p.status === 'published'
        ? (current.published_at || new Date())
        : null;
      const [row] = await sql`
        UPDATE posts SET
          slug = ${slug}, title = ${p.title}, excerpt = ${p.excerpt},
          body_html = ${p.body_html}, cover_url = ${p.cover_url},
          cover_alt = ${p.cover_alt}, tags = ${p.tags},
          meta_title = ${p.meta_title}, meta_desc = ${p.meta_desc},
          focus_keyword = ${p.focus_keyword},
          secondary_keywords = ${p.secondary_keywords}, author = ${p.author},
          status = ${p.status}, published_at = ${publishedAt}, updated_at = now()
        WHERE id = ${id} RETURNING *`;
      return json(200, { post: row });
    }

    if (route.startsWith('posts/') && method === 'DELETE') {
      const id = Number(route.split('/')[1]);
      await sql`DELETE FROM posts WHERE id = ${id}`;
      return json(200, { ok: true });
    }

    if (route === 'media' && method === 'POST') {
      // Images live in the database as data URLs. There is no object
      // store wired up, and a blog's images are few and small; this
      // keeps the whole thing to one dependency.
      const { filename, mime, data_url } = payload;
      if (!/^data:image\/(png|jpe?g|gif|webp|avif);base64,/.test(String(data_url || '')))
        return json(400, { error: 'Images only.' });
      const bytes = Math.floor(String(data_url).length * 0.75);
      if (bytes > 1_500_000) return json(400, { error: 'Keep images under 1.5 MB.' });
      const [row] = await sql`
        INSERT INTO media (filename, mime, bytes, data_url)
        VALUES (${String(filename || 'image')}, ${String(mime || 'image/png')},
                ${bytes}, ${data_url})
        RETURNING id, filename, bytes`;
      // The URL, never the data. Inlining the base64 into a post is
      // what put a page over the 6 MB a function may return.
      return json(200, { media: { ...row, url: `/media/${row.id}` } });
    }

    if (route === 'media' && method === 'GET') {
      const rows = await sql`
        SELECT id, filename, bytes, created_at
          FROM media ORDER BY created_at DESC LIMIT 60`;
      return json(200, { media: rows.map((r) => ({ ...r, url: `/media/${r.id}` })) });
    }

    return json(404, { error: 'No such endpoint.' });

  } catch (err) {
    console.error('api error', err);
    return json(500, { error: err.message || 'Something broke.' });
  }
}

function normalise(p) {
  const title = String(p.title || '').trim() || 'Untitled';
  const body = sanitize(p.body_html || '');
  return {
    title,
    slug: slugify(p.slug || title),
    body_html: body,
    excerpt: String(p.excerpt || '').trim() || textOf(body, 180),
    cover_url: String(p.cover_url || '').trim(),
    cover_alt: String(p.cover_alt || '').trim(),
    tags: Array.isArray(p.tags)
      ? p.tags.map((t) => String(t).trim()).filter(Boolean).slice(0, 8)
      : [],
    meta_title: String(p.meta_title || '').trim(),
    meta_desc: String(p.meta_desc || '').trim(),
    focus_keyword: String(p.focus_keyword || '').trim().slice(0, 120),
    secondary_keywords: Array.isArray(p.secondary_keywords)
      ? p.secondary_keywords.map((k) => String(k).trim()).filter(Boolean).slice(0, 10)
      : [],
    author: String(p.author || '').trim().slice(0, 60) || 'BillZap',
    status: p.status === 'published' ? 'published' : 'draft',
  };
}

/** Slugs are URLs; two posts cannot share one. */
async function uniqueSlug(base, ownId) {
  let slug = base, n = 1;
  for (;;) {
    const rows = ownId
      ? await sql`SELECT 1 FROM posts WHERE slug = ${slug} AND id <> ${ownId}`
      : await sql`SELECT 1 FROM posts WHERE slug = ${slug}`;
    if (!rows.length) return slug;
    slug = `${base}-${++n}`;
  }
}

// ── /try: the browser demo's form ────────────────────────────────────
//
// Business name and email in, a six-digit code out by email (Resend),
// the code back in, and a cookie that opens the demo. Until
// RESEND_API_KEY is set the code step is skipped: the lead is kept,
// unverified, and the visitor goes straight in, so /try works from the
// first deploy.

const EMAIL_RE = /^[^\s@]+@[^\s@.]+(\.[^\s@.]+)*\.[A-Za-z]{2,}$/;

/** A keyed hash: nothing stored here can be turned back into an IP or a code. */
const keyed = (s) => crypto.createHmac('sha256', process.env.SESSION_SECRET || '')
  .update(s).digest('hex');

function cleanEmail(v) { return String(v || '').trim().toLowerCase().slice(0, 254); }

async function tryStart(event, p) {
  const shop = String(p.business || '').replace(/\s+/g, ' ').trim().slice(0, 60);
  const email = cleanEmail(p.email);
  if (shop.length < 2) return json(400, { error: 'Enter your business name.' });
  if (!EMAIL_RE.test(email)) return json(400, { error: 'Enter a valid email address.' });

  await ready();
  const headers = event.headers || {};
  const ip = headers['cf-connecting-ip'] || '';
  const ipHash = ip ? keyed('ip:' + ip).slice(0, 32) : '';

  // Enough for a typo and a retry; not enough to use the form to
  // flood somebody else's inbox.
  const [{ n: perEmail }] = await sql`
    SELECT count(*)::int AS n FROM try_codes
     WHERE email = ${email} AND created_at > now() - interval '15 minutes'`;
  if (perEmail >= 3) {
    return json(429, { error: 'Too many codes for this email. Try again in 15 minutes.' });
  }
  if (ipHash) {
    const [{ n }] = await sql`
      SELECT count(*)::int AS n FROM try_codes
       WHERE ip_hash = ${ipHash} AND created_at > now() - interval '1 hour'`;
    if (n >= 10) return json(429, { error: 'Too many attempts. Try again in an hour.' });
  }

  const [lead] = await sql`
    INSERT INTO try_leads (email, business_name, marketing_ok, source, ip_hash, user_agent)
    VALUES (${email}, ${shop}, ${!!p.marketing}, ${String(p.source || '').slice(0, 80)},
            ${ipHash}, ${String(headers['user-agent'] || '').slice(0, 300)})
    ON CONFLICT (email) DO UPDATE SET
      business_name = EXCLUDED.business_name,
      marketing_ok  = try_leads.marketing_ok OR EXCLUDED.marketing_ok,
      user_agent    = EXCLUDED.user_agent,
      last_seen_at  = now()
    RETURNING id`;

  if (!process.env.RESEND_API_KEY) {
    await sql`UPDATE try_leads SET visits = visits + 1 WHERE id = ${lead.id}`;
    return json(200, { ok: true, otp: false },
      { 'Set-Cookie': issueTryCookie({ id: Number(lead.id), shop }) });
  }

  const code = String(crypto.randomInt(0, 1000000)).padStart(6, '0');
  await sql`
    INSERT INTO try_codes (email, code_hash, ip_hash, expires_at)
    VALUES (${email}, ${keyed(`code:${email}:${code}`)}, ${ipHash},
            now() + interval '10 minutes')`;
  if (!(await sendCode(email, code, shop))) {
    return json(502, { error: "We couldn't send the email. Check the address and try again." });
  }
  return json(200, { ok: true, otp: true });
}

async function tryVerify(p) {
  const email = cleanEmail(p.email);
  const code = String(p.code || '').replace(/\D/g, '').slice(0, 6);
  await ready();
  const [row] = await sql`
    SELECT id, code_hash, attempts FROM try_codes
     WHERE email = ${email} AND expires_at > now()
     ORDER BY created_at DESC LIMIT 1`;
  if (!row) return json(400, { error: 'That code has expired. Ask for a new one.' });
  if (row.attempts >= 5) return json(429, { error: 'Too many wrong codes. Ask for a new one.' });

  const want = Buffer.from(row.code_hash);
  const got = Buffer.from(keyed(`code:${email}:${code}`));
  if (code.length !== 6 || want.length !== got.length || !crypto.timingSafeEqual(want, got)) {
    await sql`UPDATE try_codes SET attempts = attempts + 1 WHERE id = ${row.id}`;
    return json(400, { error: "That code isn't right. Check the email and try again." });
  }

  await sql`DELETE FROM try_codes WHERE email = ${email}`;
  const [lead] = await sql`
    UPDATE try_leads SET verified_at = COALESCE(verified_at, now()),
                         visits = visits + 1, last_seen_at = now()
     WHERE email = ${email} RETURNING id, business_name`;
  if (!lead) return json(400, { error: 'Start again with your business name and email.' });
  return json(200, { ok: true },
    { 'Set-Cookie': issueTryCookie({ id: Number(lead.id), shop: lead.business_name }) });
}

async function sendCode(email, code, shop) {
  const from = process.env.RESEND_FROM || 'BillZap <hello@billzap.app>';
  const text = `Your BillZap demo code is ${code}\n\n` +
    `Enter it on billzap.app/try to open the demo shop for ${shop}. ` +
    `It expires in 10 minutes.\n\nIf you didn't ask for this, ignore this email.\n\n` +
    `BillZap: free GST billing app for Android\nhttps://billzap.app`;
  const html = `<div style="font-family:Arial,Helvetica,sans-serif;max-width:480px;margin:0 auto;padding:24px;color:#0D1117">
<p style="font-size:15px;margin:0 0 16px">Your BillZap demo code is</p>
<p style="font-size:34px;font-weight:700;letter-spacing:8px;margin:0 0 16px;color:#066B4A">${code}</p>
<p style="font-size:14px;line-height:1.6;margin:0 0 16px">Enter it on <b>billzap.app/try</b> to open the demo shop for <b>${esc(shop)}</b>. It expires in 10 minutes.</p>
<p style="font-size:13px;color:#5b6470;margin:0 0 24px">If you didn't ask for this, ignore this email.</p>
<p style="font-size:13px;color:#5b6470;margin:0">BillZap: free GST billing app for Android<br><a href="https://billzap.app" style="color:#066B4A">billzap.app</a></p>
</div>`;
  try {
    const r = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { Authorization: `Bearer ${process.env.RESEND_API_KEY}`,
                 'Content-Type': 'application/json' },
      body: JSON.stringify({ from, to: [email], subject: `${code} is your BillZap demo code`,
                             text, html }),
    });
    if (!r.ok) { console.error('resend', r.status, (await r.text()).slice(0, 300)); return false; }
    return true;
  } catch (e) {
    console.error('resend', e);
    return false;
  }
}

/** Every lead, for the owner: signed in to the studio, open /api/try/leads.csv. */
async function leadsCsv() {
  const rows = await sql`
    SELECT business_name, email, verified_at IS NOT NULL AS verified, marketing_ok,
           visits, source, created_at, last_seen_at
      FROM try_leads ORDER BY created_at DESC`;
  // A cell starting with = + - @ is a formula to a spreadsheet.
  const cell = (v) => {
    let s = v instanceof Date ? v.toISOString() : String(v ?? '');
    if (/^[=+\-@]/.test(s)) s = "'" + s;
    return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  };
  const head = ['business_name', 'email', 'verified', 'marketing_ok', 'visits', 'source',
                'created_at', 'last_seen_at'];
  const body = [head.join(','), ...rows.map((r) => head.map((k) => cell(r[k])).join(','))]
    .join('\n') + '\n';
  return {
    statusCode: 200,
    headers: { 'Content-Type': 'text/csv; charset=utf-8', 'Cache-Control': 'no-store',
               'Content-Disposition': 'attachment; filename="billzap-try-leads.csv"' },
    body,
  };
}
