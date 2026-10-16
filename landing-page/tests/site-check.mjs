// End-to-end check of the landing page in a real browser.
//
//   node tests/site-check.mjs [base-url]      (default http://127.0.0.1:8800)
//
// What it proves, at seven viewport sizes from a small phone to a wide
// desktop:
//   - every download button goes to the Google Play listing, exactly;
//   - every in-page anchor has a target, and the site's own pages load;
//   - no JavaScript errors;
//   - nothing makes the page scroll sideways;
//   - every motion stage keeps its contents inside its frame, and no
//     floating chip covers text on the paper, at any moment of its film;
//   - text in a stage is not cut off; tap targets are at least 24px.
//
// Exit code 1 on any failure, with a list of what failed and where.
import { chromium } from 'playwright';

const BASE = (process.argv[2] || 'http://127.0.0.1:8800').replace(/\/$/, '');
const PLAY = 'https://play.google.com/store/apps/details?id=com.billzap.app';
const VIEWPORTS = [[360, 780], [390, 844], [768, 1024], [1024, 768], [1280, 800], [1440, 900], [1920, 1080]];
// ONLY=360x780,390x844 to run a subset while working on one size.
const ONLY = (process.env.ONLY || '').split(',').filter(Boolean);
// The films are sampled through a whole cycle at these sizes; the
// static checks run at every size.
const FILM_VIEWPORTS = new Set(['360x780', '390x844', '768x1024', '1024x768', '1440x900']);
// The comparison pages, which share the header, footer and download
// buttons and get the same layout checks at every size.
const ALT_PAGES = ['/alternatives/', ...['vyapar', 'mybillbook', 'khatabook', 'zoho-invoice', 'swipe', 'tally']
  .map((s) => `/alternatives/${s}/`)];
const IGNORE_CONSOLE = /googletagmanager|google-analytics|ERR_TUNNEL|ERR_NAME_NOT_RESOLVED|net::ERR_/;

const fails = [];
const fail = (where, what) => { fails.push(`${where}: ${what}`); };
let checks = 0;
const ok = () => { checks++; };

const browser = await chromium.launch({
  executablePath: process.env.CHROME_PATH || undefined,
});

// ── Pages and files the site serves ───────────────────────────────
{
  const ctx = await browser.newContext();
  const p = await ctx.newPage();
  for (const path of ['/', '/privacy/', '/robots.txt', '/sitemap.xml', '/llms.txt', '/site.webmanifest', ...ALT_PAGES]) {
    const r = await p.goto(BASE + path);
    if (!r || r.status() !== 200) fail(path, `status ${r && r.status()}`); else ok();
  }
  // The privacy page shares the header and footer, so its download
  // buttons must go to the same place.
  await p.goto(BASE + '/privacy/');
  const pl = await p.$$eval('a[data-store]', (as) => as.map((a) => a.href));
  if (pl.length < 2) fail('/privacy/', `only ${pl.length} download buttons found`);
  for (const h of pl) { if (h !== PLAY) fail('/privacy/', `download button goes to ${h}`); else ok(); }
  // The footer links every comparison page, from every page.
  const fl = await p.$$eval('.ftr a[href^="/alternatives/"]', (as) => as.map((a) => a.getAttribute('href')));
  for (const path of ALT_PAGES.slice(1)) {
    if (!fl.includes(path)) fail('footer', `no link to ${path}`); else ok();
  }
  await ctx.close();
}

// ── Comparison pages, at every size ────────────────────────────────
for (const [w, h] of VIEWPORTS) {
  const tag = `${w}x${h}`;
  if (ONLY.length && !ONLY.includes(tag)) continue;
  const ctx = await browser.newContext({ viewport: { width: w, height: h } });
  const p = await ctx.newPage();
  const errors = [];
  p.on('pageerror', (e) => errors.push(e.message));
  p.on('console', (m) => { if (m.type() === 'error' && !IGNORE_CONSOLE.test(m.text())) errors.push(m.text()); });
  for (const path of ALT_PAGES) {
    const where = `${tag} ${path}`;
    await p.goto(BASE + path, { waitUntil: 'load' });
    const height = await p.evaluate(() => document.documentElement.scrollHeight);
    for (let y = 0; y < height; y += h * 0.6) {
      await p.evaluate((y) => scrollTo(0, y), y);
      await p.waitForTimeout(120);
    }
    await p.waitForTimeout(500);
    const r = await p.evaluate(() => {
      const W = document.documentElement.clientWidth;
      // Revealed means the observer has fired; the fade itself may still
      // be running, so opacity is not the thing to measure.
      const hidden = document.querySelectorAll('html.js .rv:not(.in)').length;
      const small = [...document.querySelectorAll('a.btn, .alt-link, .nav a')].filter((n) => {
        const b = n.getBoundingClientRect();
        return b.width && getComputedStyle(n).display !== 'none' && (b.height < 24 || b.width < 24);
      }).map((n) => n.textContent.trim().slice(0, 30));
      return {
        sideways: document.documentElement.scrollWidth > W + 1,
        dl: [...document.querySelectorAll('a[data-store]')].map((a) => a.href),
        hidden, small,
        h1: document.querySelectorAll('h1').length,
        faq: [...document.querySelectorAll('script[type="application/ld+json"]')]
          .some((s) => s.textContent.includes('"FAQPage"')),
      };
    });
    if (r.sideways) fail(where, 'page scrolls sideways'); else ok();
    if (r.dl.length < 3) fail(where, `only ${r.dl.length} download buttons found`);
    for (const h of r.dl) { if (h !== PLAY) fail(where, `download button goes to ${h}`); else ok(); }
    if (r.hidden) fail(where, `${r.hidden} sections never revealed`); else ok();
    for (const s of r.small) fail(where, `tap target under 24px: "${s}"`);
    if (r.h1 !== 1) fail(where, `${r.h1} h1 elements`); else ok();
    if (path !== '/alternatives/' && !r.faq) fail(where, 'no FAQPage data'); else ok();
  }
  for (const e of errors) fail(tag, `JS error on a comparison page: ${e}`);
  if (!errors.length) ok();
  await ctx.close();
}

for (const [w, h] of VIEWPORTS) {
  const tag = `${w}x${h}`;
  if (ONLY.length && !ONLY.includes(tag)) continue;
  const ctx = await browser.newContext({ viewport: { width: w, height: h } });
  const p = await ctx.newPage();
  const errors = [];
  p.on('pageerror', (e) => errors.push(e.message));
  p.on('console', (m) => { if (m.type() === 'error' && !IGNORE_CONSOLE.test(m.text())) errors.push(m.text()); });
  await p.goto(BASE + '/', { waitUntil: 'load' });

  // Walk the page so every section renders and every reveal fires.
  const height = await p.evaluate(() => document.documentElement.scrollHeight);
  for (let y = 0; y < height; y += h * 0.6) {
    await p.evaluate((y) => scrollTo(0, y), y);
    await p.waitForTimeout(120);
  }
  await p.waitForTimeout(700);

  // ── Download buttons ──
  const dl = await p.$$eval('a', (as) => as
    .filter((a) => /download|get it|google play/i.test(a.textContent) || a.hasAttribute('data-store'))
    .map((a) => ({ text: a.textContent.trim().replace(/\s+/g, ' '), href: a.href })));
  if (dl.length < 3) fail(tag, `only ${dl.length} download buttons found`);
  for (const a of dl) {
    if (a.href !== PLAY) fail(tag, `download button "${a.text}" goes to ${a.href}`); else ok();
  }

  // ── Anchors ──
  const missing = await p.$$eval('a[href^="#"]', (as) => as
    .map((a) => a.getAttribute('href').slice(1))
    .filter((id) => id && !document.getElementById(id)));
  for (const id of new Set(missing)) fail(tag, `link to #${id} has no target`);
  if (!missing.length) ok();

  // ── Sideways scroll ──
  const over = await p.evaluate(() => {
    const W = document.documentElement.clientWidth;
    if (document.documentElement.scrollWidth <= W + 1) return [];
    return [...document.querySelectorAll('body *')]
      .filter((n) => {
        const r = n.getBoundingClientRect();
        if (!r.width) return false;
        // Inside a clipping ancestor is fine (marquee, stages).
        for (let a = n.parentElement; a; a = a.parentElement) {
          const o = getComputedStyle(a).overflowX;
          if (o === 'hidden' || o === 'clip' || o === 'auto') return false;
        }
        return r.right > W + 1 || r.left < -1;
      })
      .slice(0, 6).map((n) => n.tagName.toLowerCase() + (n.className ? '.' + String(n.className).split(' ')[0] : ''));
  });
  if (over.length) fail(tag, `page scrolls sideways; widest: ${over.join(', ')}`); else ok();

  // ── Tap targets ──
  const small = await p.$$eval('a.btn, button, .tlink, .nav a, .ex-ch button', (ns) => ns
    .filter((n) => {
      const r = n.getBoundingClientRect(), s = getComputedStyle(n);
      if (!r.width || s.visibility === 'hidden' || s.display === 'none') return false;
      // .ex-ch buttons are stretched over their whole list item.
      const box = n.closest('.ex-ch li')?.getBoundingClientRect() || r;
      return box.height < 24 || box.width < 24;
    })
    .map((n) => n.textContent.trim().slice(0, 30) || n.getAttribute('aria-label')));
  for (const s of small) fail(tag, `tap target under 24px: "${s}"`);
  if (!small.length) ok();

  // ── Motion stages ──
  // Sample each film. At the sampled sizes the stage is scrolled into
  // view and watched for its whole cycle; elsewhere one frame is
  // checked. A finding is reported once per stage and kind.
  const stages = await p.$$eval('.mo', (ns) => ns.map((n, i) => {
    n.setAttribute('data-test-i', i);
    return { i, name: n.className.replace(/\s+/g, ' ').trim(), cycle: 0 };
  }));
  const film = FILM_VIEWPORTS.has(tag);
  for (const st of stages) {
    const sel = `[data-test-i="${st.i}"]`;
    await p.locator(sel).scrollIntoViewIfNeeded();
    // The explainer cycles five scenes; the others loop one film.
    const cycleMs = film ? await p.$eval(sel, (n) => {
      if (n.classList.contains('ex-stage')) return 31000;
      const d = (n.getAttribute('data-steps') || '').split(',').map(Number).filter(Boolean);
      return d.reduce((a, b) => a + b, 0) + (+n.getAttribute('data-hold') || 2400) + (n.hasAttribute('data-defer') ? 6500 : 600);
    }) : 0;
    const seen = new Set();
    const t0 = Date.now();
    do {
      const found = await p.$eval(sel, (stage) => {
        const out = [];
        const S = stage.getBoundingClientRect();
        const shown = (n) => {
          for (let a = n; a && a !== stage; a = a.parentElement) {
            const s = getComputedStyle(a);
            if (s.display === 'none' || s.visibility === 'hidden' || +s.opacity < 0.6) return false;
          }
          return true;
        };
        // 1. Anything visible poking out of the frame.
        stage.querySelectorAll('.pp, .ck, .chat, .rows, .kpis, .rates, .exp, .sig, .stack, .cnt, .split-out, .mic').forEach((n) => {
          if (!shown(n)) return;
          const r = n.getBoundingClientRect();
          if (r.left < S.left - 1 || r.right > S.right + 1 || r.top < S.top - 1 || r.bottom > S.bottom + 1)
            out.push(`clipped by the frame: ${n.className.split(' ').slice(0, 3).join('.')}`);
        });
        // 2. A chip over text on a paper card.
        const chips = [...stage.querySelectorAll('.ck')].filter(shown);
        const texts = [...stage.querySelectorAll('.pp b, .pp small, .pp span:not(:has(*)), .pp q')]
          .filter((t) => shown(t) && t.textContent.trim() && !t.closest('.ck'));
        for (const c of chips) {
          if (c.closest('.pp')) continue;
          const a = c.getBoundingClientRect();
          for (const t of texts) {
            const b = t.getBoundingClientRect();
            const x = Math.min(a.right, b.right) - Math.max(a.left, b.left);
            const y = Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top);
            if (x > 2 && y > 2) { out.push(`chip "${c.textContent.trim().slice(0, 24)}" covers "${t.textContent.trim().slice(0, 24)}"`); break; }
          }
        }
        // 3. The pause button over a chip.
        const pp = stage.querySelector('.mo-pp');
        if (pp && !pp.hidden) {
          const a = pp.getBoundingClientRect();
          for (const c of [...stage.querySelectorAll('.ck, .pp, .rem, .chat')].filter(shown)) {
            const b = c.getBoundingClientRect();
            if (Math.min(a.right, b.right) - Math.max(a.left, b.left) > 2 && Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top) > 2) {
              out.push(`pause button overlaps ${c.className.split(' ')[0]} "${c.textContent.trim().slice(0, 20)}"`); break;
            }
          }
        }
        // 4. Single-line text cut off.
        stage.querySelectorAll('.ck, .tag, .pp b').forEach((n) => {
          if (shown(n) && n.scrollWidth > n.clientWidth + 2 && getComputedStyle(n).overflow !== 'visible')
            out.push(`text cut off: "${n.textContent.trim().slice(0, 24)}"`);
        });
        return out;
      });
      for (const f of found) seen.add(f);
      if (film) await p.waitForTimeout(400);
    } while (film && Date.now() - t0 < cycleMs);
    if (seen.size) for (const f of seen) fail(`${tag} ${st.name.split(' ').slice(0, 3).join('.')}`, f);
    else ok();
  }

  for (const e of errors) fail(tag, `JS error: ${e}`);
  if (!errors.length) ok();
  await ctx.close();
  console.log(`  ${tag.padEnd(10)} checked`);
}

await browser.close();
console.log(`\n${checks} checks passed, ${fails.length} failed`);
for (const f of fails) console.log('  FAIL  ' + f);
process.exit(fails.length ? 1 : 0);
