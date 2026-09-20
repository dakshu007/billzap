// Everything the studio talks to. One function, routed on the path
// after /api/, because a handful of small handlers in separate files
// would each pay their own cold start.
import { sql, ready } from './lib/db.js';
import { isAuthed, issueCookie, clearCookie, verifyPassword } from './lib/auth.js';
import { sanitize, textOf, slugify } from './lib/html.js';

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

    // ── Everything below needs a session ─────────────────────────
    if (!isAuthed(event.headers || {})) return json(401, { error: 'Not signed in.' });
    await ready();

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
