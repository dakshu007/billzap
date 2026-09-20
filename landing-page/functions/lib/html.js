// Escaping and sanitising.
//
// The editor produces HTML, which then gets rendered into a public
// page. Only one person can write posts, so this is not guarding
// against a hostile author — it guards against a paste. Copying a
// paragraph out of another site brings that site's markup with it:
// tracking pixels, inline handlers, style blocks, the occasional
// <script>. An allowlist means whatever arrives, only these tags and
// attributes ever reach a reader.
export function esc(s) {
  return String(s ?? '')
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

const ALLOWED = {
  p: [], br: [], strong: [], b: [], em: [], i: [], u: [], s: [],
  h2: [], h3: [], h4: [], blockquote: [], pre: [], code: [],
  ul: [], ol: [], li: [], hr: [],
  a: ['href', 'title'],
  img: ['src', 'alt', 'width', 'height'],
  table: [], thead: [], tbody: [], tr: [], th: [], td: [],
};

function safeUrl(u) {
  const v = String(u || '').trim();
  // Anything that is not plainly http(s), a site-relative path, an
  // anchor, a mailto or an inline image is dropped — that is where
  // javascript: and data:text/html would otherwise get in.
  if (/^(https?:\/\/|\/|#|mailto:|tel:)/i.test(v)) return v;
  if (/^data:image\/(png|jpe?g|gif|webp|avif);base64,[A-Za-z0-9+/=]+$/i.test(v)) return v;
  return '';
}

export function sanitize(html) {
  let out = String(html ?? '');

  // Whole elements whose *content* is also dangerous go first, tag
  // and children together.
  out = out.replace(/<(script|style|iframe|object|embed|noscript|template|svg|math)\b[\s\S]*?<\/\1\s*>/gi, '');
  out = out.replace(/<!--[\s\S]*?-->/g, '');

  out = out.replace(/<\/?([a-zA-Z][a-zA-Z0-9]*)\b([^>]*)>/g, (m, tagRaw, attrs) => {
    const tag = tagRaw.toLowerCase();
    if (!(tag in ALLOWED)) return '';
    if (m.startsWith('</')) return `</${tag}>`;

    const keep = [];
    const allowed = ALLOWED[tag];
    const re = /([a-zA-Z_:][-a-zA-Z0-9_:.]*)\s*=\s*("[^"]*"|'[^']*'|[^\s>]+)/g;
    let a;
    while ((a = re.exec(attrs))) {
      const name = a[1].toLowerCase();
      if (!allowed.includes(name)) continue;       // drops on*, style, class, data-*
      let val = a[2].replace(/^["']|["']$/g, '');
      if (name === 'href' || name === 'src') {
        val = safeUrl(val);
        if (!val) continue;
      }
      if ((name === 'width' || name === 'height') && !/^\d{1,4}$/.test(val)) continue;
      keep.push(`${name}="${esc(val)}"`);
    }
    if (tag === 'a') {
      keep.push('rel="noopener nofollow ugc"');
      keep.push('target="_blank"');
    }
    if (tag === 'img') keep.push('loading="lazy"', 'decoding="async"');
    const selfClosing = tag === 'br' || tag === 'img' || tag === 'hr';
    return `<${tag}${keep.length ? ' ' + keep.join(' ') : ''}${selfClosing ? '' : ''}>`;
  });

  return out;
}

/** Plain text, for excerpts and meta descriptions. */
export function textOf(html, limit = 0) {
  let t = String(html ?? '')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"').replace(/&#39;/g, "'")
    .replace(/\s+/g, ' ').trim();
  if (limit && t.length > limit) t = t.slice(0, limit - 1).replace(/\s\S*$/, '') + '…';
  return t;
}

export function slugify(s) {
  return String(s || '').toLowerCase().trim()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 80) || 'post';
}
