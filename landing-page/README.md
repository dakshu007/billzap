# BillZap landing page

A hand-built static site. `index.html` is generated — edit the sources
in `build/` and run the build, never edit the output.

```
cd build && python3 build.py
```

## Why not React / Next / Three.js

The brief asked for both a Three.js-driven site and 100 across every
Lighthouse category. Those two pull against each other: Three.js is
about 150 KB gzipped of parser-blocking JavaScript before a single
triangle is drawn, and a React hydration pass on top of it puts total
blocking time well outside the range where Performance scores 100 on a
throttled mobile profile.

The numeric requirement won. This page ships zero framework JavaScript
and about 1 KB of vanilla script for scroll reveals, which is why it
measures 100/100/100/100 on both mobile and desktop rather than a high
nineties. The "premium" work is done with CSS — ambient gradient
washes, a device frame built from a border radius and two shadows,
IntersectionObserver reveals, and native smooth scrolling.

If a 3D hero becomes worth the trade later, the place to put it is a
lazily imported island below the fold, so it never touches LCP.

## Layout

```
build/
  page.html      body markup; {{ico:name}} placeholders for Lucide icons
  styles.css     the whole stylesheet; inlined into <style> at build
  build.py       assembles index.html, emits JSON-LD, subsets the fonts
  lucide.json    extracted Lucide SVG bodies (ISC licence)
  fonts-src/     full latin woff2 files, subset at build time
index.html       generated — do not edit
llms.txt         product summary written for AI crawlers
assets/          fonts (subset), app screenshots, icons, OG card
worker.js        Cloudflare Worker: redirects, headers, blog/studio/API routing
wrangler.jsonc   Cloudflare config: custom domains, static assets
_headers         cache headers for /assets/* (served without the Worker)
functions/       blog, studio and API handlers, called by worker.js
```

## Build steps explained

- **CSS is inlined.** A `<link rel=stylesheet>` is render-blocking; at
  16 KB the round trip costs more than the bytes.
- **Icons are inlined SVG** from the `lucide-static` package. An icon
  font would be a render-blocking request that flashes its ligature
  shortcodes before it loads.
- **Fonts are subset to the page's own glyphs** at build time, taking
  the five faces from 95 KB to 51 KB. Google's "latin" subset covers
  every Western European language; this page is English. The
  Indian-language names in the languages section fall through to the
  system's Devanagari, Tamil and Arabic faces on purpose.
- **The FAQ is written once** in `build.py` and emitted twice — as
  `<details>` markup and as FAQPage JSON-LD — so the two cannot drift.

## Measured

Lighthouse, against a local server with gzip and the production cache
headers (the numbers are lower against an uncompressed server, which is
not a deployment that exists):

| | Perf | A11y | Best practices | SEO | Agentic |
|---|---|---|---|---|---|
| Mobile | 100 | 100 | 100 | 100 | 100 |
| Desktop | 100 | 100 | 100 | 100 | 100 |

Total page weight is about 194 KB, of which 16 KB is the gzipped HTML.

## SEO

- Focus keyword: **free GST billing app**
- Primary: GST billing app, offline billing app, GST invoice app India
- Secondary: UPI QR invoice, voice billing app, GSTR-1 export, billing
  app for small business, tax invoice app

Structured data covers SoftwareApplication, Organization, WebSite,
WebPage, FAQPage and HowTo. `robots.txt` names the AI crawlers
explicitly and `llms.txt` gives them a written product summary.

## Deploying

Cloudflare Worker `billzap` with static assets, on the custom domains
`billzap.app` and `www.billzap.app` (www 301s to the apex). Pushing a
change under `landing-page/` runs `.github/workflows/landing-page.yml`,
which rebuilds, stages `dist/` and runs `wrangler deploy`. The deploy
creates the domains' DNS records and certificates itself.

Repository secrets: `CLOUDFLARE_API_TOKEN` (the "Edit Cloudflare
Workers" template, with billzap.app in Zone Resources) and
`CLOUDFLARE_ACCOUNT_ID`. The Worker's own secrets — `DATABASE_URL`,
`ADMIN_PATH`, `ADMIN_PASSWORD`, `SESSION_SECRET` — are set by the
workflow; see the comment at the top of it.

Local run: stage `dist/` as the workflow does, put the four secrets in
`landing-page/.dev.vars` (git-ignored), then `npx wrangler dev`.

## Testing

`tests/site-check.mjs` drives Chromium through the page at seven sizes,
from a 360px phone to 1920px, and fails on any of: a download button
not pointing at the Google Play listing, an in-page link with no
target, a JavaScript error, sideways scroll, a tap target under 24px,
and — sampled through each film's whole cycle at five sizes — a motion
stage whose contents leave its frame, a chip covering text, the pause
button over content, or text cut off.

    npm test                          # against http://127.0.0.1:8800
    node tests/site-check.mjs https://billzap.app

CI runs it against the live site after every deploy (the
`browser-test` job in `.github/workflows/landing-page.yml`).
