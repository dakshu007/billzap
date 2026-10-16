// The site on Cloudflare: one Worker in front of the static files.
//
// The static pages are Workers static assets (dist/, staged by the
// deploy workflow). This file is what netlify.toml used to be — the
// redirects, the headers, and the routing to the three dynamic
// handlers — plus a thin adapter, because the handlers in functions/
// are written against the Netlify (Lambda-style) event shape and there
// is no reason to rewrite them: they take an event and return
// { statusCode, headers, body }, and that maps onto Request/Response
// one to one.
//
// Everything except /assets/* runs through here (see wrangler.jsonc).
// /assets/* is fonts and images: served straight from the asset store,
// headers from _headers, never costing a Worker invocation.
import { handler as blog } from './functions/blog.js';
import { handler as api } from './functions/api.js';
import { handler as studio } from './functions/studio.js';

const HOST = 'billzap.app';

// ── Security headers ───────────────────────────────────────────────
// Unchanged from netlify.toml — see the comment there in git history
// for why the CSP grants exactly these hosts.
const SECURITY = {
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'SAMEORIGIN',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Permissions-Policy': 'geolocation=(), microphone=(), camera=(), interest-cohort=()',
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
  'Content-Security-Policy': "default-src 'self'; script-src 'self' 'unsafe-inline' https://www.googletagmanager.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https://www.google-analytics.com https://www.googletagmanager.com; font-src 'self'; connect-src 'self' https://www.google-analytics.com https://*.google-analytics.com https://*.analytics.google.com https://www.googletagmanager.com https://script.google.com https://script.googleusercontent.com; form-action 'self'; frame-ancestors 'self'; base-uri 'self'; object-src 'none'; upgrade-insecure-requests",
};

// ── Redirects ──────────────────────────────────────────────────────
// First match wins, as in netlify.toml.
const EXACT = {
  '/download': ['/#download', 302],
  '/features': ['/#features', 302],
  '/faq': ['/#faq', 302],
  '/case-study.html': ['/', 301],     // the old case study is gone
  '/privacy.html': ['/privacy/', 301],
  '/README.md': ['/', 301],
};
// Earlier deploys published the whole landing-page folder; anything
// crawled from it goes to the real page rather than a 404.
const PREFIX = [['/build/', '/'], ['/google-sheet/', '/']];

// ── Dynamic routes ─────────────────────────────────────────────────
function route(path) {
  if (path === '/blog' || path.startsWith('/blog/') || path.startsWith('/media/') ||
      path === '/sitemap-blog.xml') return blog;
  if (path === '/api' || path.startsWith('/api/')) return api;
  if (path === '/s' || path.startsWith('/s/')) return studio;
  return null;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // One hostname. www, and the workers.dev address, both 301 to the
    // apex so search engines see a single site.
    if (url.hostname !== HOST && url.hostname !== 'localhost' && url.hostname !== '127.0.0.1') {
      return Response.redirect(`https://${HOST}${url.pathname}${url.search}`, 301);
    }

    const path = url.pathname;
    const exact = EXACT[path];
    if (exact) return redirect(exact[0], exact[1]);
    for (const [from, to] of PREFIX) if (path.startsWith(from)) return redirect(to, 301);

    const fn = route(path);
    const res = fn ? await run(fn, request, url) : await env.ASSETS.fetch(request);
    return withHeaders(res, path);
  },
};

function redirect(location, status) {
  return new Response(null, { status, headers: { Location: location } });
}

/** Netlify event in, Netlify result out. */
async function run(fn, request, url) {
  const hasBody = !['GET', 'HEAD'].includes(request.method);
  const event = {
    path: url.pathname,
    httpMethod: request.method,
    headers: Object.fromEntries(request.headers),   // lower-cased keys, as on Netlify
    queryStringParameters: Object.fromEntries(url.searchParams),
    body: hasBody ? await request.text() : null,
    isBase64Encoded: false,
    rawUrl: request.url,
  };

  let r;
  try {
    r = await fn(event);
  } catch (err) {
    console.error('handler threw', err);
    r = { statusCode: 500, headers: { 'Content-Type': 'text/plain' }, body: 'Server error' };
  }

  const headers = new Headers();
  for (const [k, v] of Object.entries(r.headers || {})) headers.set(k, String(v));
  for (const [k, vs] of Object.entries(r.multiValueHeaders || {})) {
    for (const v of vs) headers.append(k, String(v));
  }

  const status = r.statusCode || 200;
  let body = r.body ?? '';
  if (r.isBase64Encoded) body = Buffer.from(body, 'base64');
  if (request.method === 'HEAD' || [101, 204, 205, 304].includes(status)) body = null;
  return new Response(body, { status, headers });
}

/** The [[headers]] blocks of netlify.toml. */
function withHeaders(res, path) {
  const out = new Response(res.body, res);   // asset responses are immutable
  const h = out.headers;
  for (const [k, v] of Object.entries(SECURITY)) if (!h.has(k)) h.set(k, v);

  if (path.startsWith('/s/') || path === '/s') {
    // The studio must never be indexed, cached or sent as a referrer.
    h.set('X-Robots-Tag', 'noindex, nofollow, noarchive');
    h.set('Cache-Control', 'no-store');
    h.set('Referrer-Policy', 'no-referrer');
  } else if (path.startsWith('/api/') || path === '/api') {
    h.set('X-Robots-Tag', 'noindex, nofollow');
    h.set('Cache-Control', 'no-store');
  } else if (path === '/llms.txt' || path === '/llms-full.txt') {
    // Read by crawlers that expect text/plain, not a download.
    h.set('Content-Type', 'text/plain; charset=utf-8');
    h.set('Cache-Control', 'public, max-age=3600');
  } else if (path === '/sitemap.xml') {
    h.set('Content-Type', 'application/xml; charset=utf-8');
  } else if (h.get('Content-Type')?.startsWith('text/html') && !route(path)) {
    // HTML must revalidate so a deploy is visible immediately.
    h.set('Cache-Control', 'public, max-age=0, must-revalidate');
  }
  return out;
}
