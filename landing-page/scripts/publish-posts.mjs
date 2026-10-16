// Publish the blog posts kept in content/blog/ into the database.
//
//   DATABASE_URL=… node scripts/publish-posts.mjs [--dry-run]
//
// Each post is one Markdown file with a front-matter block:
//
//   ---
//   title: The headline, as it appears on the page
//   slug: the-url-slug
//   meta_title: The <title>, if it should differ from the headline
//   meta_desc: The meta description, 150-160 characters
//   focus_keyword: primary keyword
//   secondary_keywords: [one, two, three]
//   tags: [GST billing, Comparisons]
//   excerpt: The line shown on the blog index
//   publish_at: 2026-10-16T09:00:00+05:30
//   author: BillZap Team
//   ---
//
// Posts are upserted by slug, so editing a file and pushing updates the
// live post. publish_at is when the post goes live: the blog only shows
// posts whose time has come, so a post committed today for tomorrow
// evening appears tomorrow evening, with nothing to run at that moment.
// The studio is still there for quick edits; a post edited in the
// studio and then changed here is overwritten by the file.
import { readdirSync, readFileSync } from 'node:fs';
import { marked } from 'marked';
import { sql, ready } from '../functions/lib/db.js';
import { textOf } from '../functions/lib/html.js';

const DIR = new URL('../content/blog/', import.meta.url);
const DRY = process.argv.includes('--dry-run');
const SITE_HOST = 'billzap.app';

function frontMatter(src, file) {
  const m = src.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!m) throw new Error(`${file}: no front matter`);
  const meta = {};
  for (const line of m[1].split('\n')) {
    const kv = line.match(/^([a-z_]+):\s*(.*)$/);
    if (!kv) continue;
    let v = kv[2].trim();
    if (v.startsWith('[') && v.endsWith(']')) {
      v = v.slice(1, -1).split(',').map((x) => x.trim().replace(/^["']|["']$/g, '')).filter(Boolean);
    } else {
      v = v.replace(/^["']|["']$/g, '');
    }
    meta[kv[1]] = v;
  }
  for (const k of ['title', 'slug', 'meta_desc', 'focus_keyword', 'publish_at']) {
    if (!meta[k]) throw new Error(`${file}: front matter is missing ${k}`);
  }
  if (!/^[a-z0-9-]+$/.test(meta.slug)) throw new Error(`${file}: slug must be a-z, 0-9 and hyphens`);
  const at = new Date(meta.publish_at);
  if (isNaN(at)) throw new Error(`${file}: publish_at is not a date`);
  return { meta, body: m[2], at };
}

function toHtml(md) {
  let html = marked.parse(md, { gfm: true, breaks: false });
  // The headline is rendered by the page; a leading h1 in the file
  // would make two.
  html = html.replace(/^\s*<h1[^>]*>[\s\S]*?<\/h1>\s*/i, '');
  // Links off the site open in a new tab without handing over the
  // opener. Links within it stay plain, followed links.
  html = html.replace(/<a href="(https?:\/\/[^"]+)"/g, (m, href) =>
    new URL(href).hostname.endsWith(SITE_HOST) ? m : `<a href="${href}" rel="noopener" target="_blank"`);
  return html;
}

const files = readdirSync(DIR).filter((f) => f.endsWith('.md')).sort();
if (!files.length) { console.log('No posts in content/blog/.'); process.exit(0); }
if (!DRY) await ready();

const now = new Date();
for (const file of files) {
  const { meta, body, at } = frontMatter(readFileSync(new URL(file, DIR), 'utf8'), file);
  const html = toHtml(body);
  const words = textOf(html).split(/\s+/).filter(Boolean).length;
  const row = {
    slug: meta.slug,
    title: meta.title,
    excerpt: meta.excerpt || textOf(html, 180),
    body_html: html,
    tags: Array.isArray(meta.tags) ? meta.tags : [],
    meta_title: meta.meta_title || '',
    meta_desc: meta.meta_desc,
    focus_keyword: meta.focus_keyword,
    secondary_keywords: Array.isArray(meta.secondary_keywords) ? meta.secondary_keywords : [],
    author: meta.author || 'BillZap',
  };
  const when = at <= now ? 'live now' : `goes live ${at.toISOString()}`;
  if (DRY) { console.log(`  dry   ${row.slug.padEnd(44)} ${String(words).padStart(5)} words  ${when}`); continue; }

  const [existing] = await sql`SELECT id FROM posts WHERE slug = ${row.slug}`;
  if (existing) {
    await sql`
      UPDATE posts SET
        title = ${row.title}, excerpt = ${row.excerpt}, body_html = ${row.body_html},
        tags = ${row.tags}, meta_title = ${row.meta_title}, meta_desc = ${row.meta_desc},
        focus_keyword = ${row.focus_keyword}, secondary_keywords = ${row.secondary_keywords},
        author = ${row.author}, status = 'published', published_at = ${at}, updated_at = now()
      WHERE id = ${existing.id}`;
  } else {
    await sql`
      INSERT INTO posts (slug, title, excerpt, body_html, tags, meta_title, meta_desc,
                         focus_keyword, secondary_keywords, author, status, published_at)
      VALUES (${row.slug}, ${row.title}, ${row.excerpt}, ${row.body_html}, ${row.tags},
              ${row.meta_title}, ${row.meta_desc}, ${row.focus_keyword},
              ${row.secondary_keywords}, ${row.author}, 'published', ${at})`;
  }
  console.log(`  ${existing ? 'upd ' : 'new '}  ${row.slug.padEnd(44)} ${String(words).padStart(5)} words  ${when}`);
}
