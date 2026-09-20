// Neon, over its HTTP driver.
//
// A Netlify function is a short-lived process with no stable place to
// keep a TCP pool, so the normal pg client spends most of its life
// opening and closing connections. The serverless driver talks to
// Neon over HTTP instead: one request, one round trip, nothing to
// leak between invocations.
import { neon } from '@neondatabase/serverless';

let _sql = null;

/** Strip options the HTTP driver has no use for.
 *
 * A Neon connection string is written for libpq and carries options
 * that only mean something to a TCP client — channel_binding is the
 * one that bites, since there is no TLS channel to bind to over
 * HTTP. Passing the string through untouched is what a connection
 * error at startup usually turns out to be.
 */
export function normaliseUrl(raw) {
  const u = new URL(raw);
  const keep = new URLSearchParams();
  const ssl = u.searchParams.get('sslmode');
  if (ssl) keep.set('sslmode', ssl);
  u.search = keep.toString();
  return u.toString();
}

export function sql(...args) {
  if (!_sql) {
    const url = process.env.DATABASE_URL;
    if (!url) throw new Error('DATABASE_URL is not set');
    _sql = neon(normaliseUrl(url));
  }
  return _sql(...args);
}

/** An error worth putting on a page: no host, no user, no password. */
export function redact(err) {
  return String(err?.message || err || 'unknown')
    .replace(/postgres(?:ql)?:\/\/[^\s'"]*/gi, '[connection string]')
    .replace(/\b[\w.-]+\.neon\.tech\b/gi, '[host]')
    .replace(/npg_[A-Za-z0-9]+/g, '[password]')
    .slice(0, 200);
}

// The schema, applied on demand.
//
// Every statement is idempotent, so this can run on any cold start
// without a migration runner, a checked-in lock file, or a step
// somebody has to remember. `_ready` keeps it to once per process.
let _ready = null;

export function ready() {
  if (!_ready) _ready = migrate().catch((e) => { _ready = null; throw e; });
  return _ready;
}

async function migrate() {
  await sql`
    CREATE TABLE IF NOT EXISTS posts (
      id           BIGSERIAL PRIMARY KEY,
      slug         TEXT UNIQUE NOT NULL,
      title        TEXT NOT NULL,
      excerpt      TEXT NOT NULL DEFAULT '',
      body_html    TEXT NOT NULL DEFAULT '',
      cover_url    TEXT NOT NULL DEFAULT '',
      cover_alt    TEXT NOT NULL DEFAULT '',
      tags         TEXT[] NOT NULL DEFAULT '{}',
      meta_title   TEXT NOT NULL DEFAULT '',
      meta_desc    TEXT NOT NULL DEFAULT '',
      status       TEXT NOT NULL DEFAULT 'draft',
      author       TEXT NOT NULL DEFAULT 'BillZap',
      created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
      published_at TIMESTAMPTZ
    )`;

  // Listing the blog is "published, newest first" and nothing else,
  // so that is the index.
  await sql`
    CREATE INDEX IF NOT EXISTS posts_published_idx
      ON posts (published_at DESC)
      WHERE status = 'published'`;

  // Keyword fields. Added after the table existed, so they arrive as
  // ALTERs rather than in the CREATE above.
  await sql`ALTER TABLE posts ADD COLUMN IF NOT EXISTS focus_keyword TEXT NOT NULL DEFAULT ''`;
  await sql`ALTER TABLE posts ADD COLUMN IF NOT EXISTS secondary_keywords TEXT[] NOT NULL DEFAULT '{}'`;

  await sql`
    CREATE TABLE IF NOT EXISTS media (
      id         BIGSERIAL PRIMARY KEY,
      filename   TEXT NOT NULL,
      mime       TEXT NOT NULL,
      bytes      INTEGER NOT NULL,
      data_url   TEXT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )`;

  await unInlineImages();
  return true;
}

/** Move already-published images out of the HTML and behind /media/<id>.
 *
 * Images were first stored as data URLs and pasted straight into the
 * post body. That works until a post is opened: a 2 MB photo is ~2.7 MB
 * of base64, and a Netlify function may return at most 6 MB, so the
 * page died with ResponseSizeTooLarge rather than rendering. Images are
 * served from their own URL now; this repoints anything written before
 * that change.
 *
 * Idempotent, and cheap to skip: the EXISTS check is one indexless
 * scan of a table with a handful of rows, and after the first run it
 * finds nothing.
 */
async function unInlineImages() {
  const [{ pending }] = await sql`
    SELECT EXISTS (
      SELECT 1 FROM posts
       WHERE body_html LIKE '%data:image%' OR cover_url LIKE 'data:image%'
    ) AS pending`;
  if (!pending) return;

  const rows = await sql`SELECT id, data_url FROM media`;
  for (const m of rows) {
    await sql`
      UPDATE posts
         SET body_html = replace(body_html, ${m.data_url}, ${'/media/' + m.id}),
             cover_url = CASE WHEN cover_url = ${m.data_url}
                              THEN ${'/media/' + m.id} ELSE cover_url END
       WHERE body_html LIKE '%data:image%' OR cover_url = ${m.data_url}`;
  }
  console.log(`unInlineImages: repointed ${rows.length} image(s)`);
}
