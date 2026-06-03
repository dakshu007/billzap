# BillZap landing page

Two pages, both single-file, light-mode, cream `#F6F2E9` app theme,
fully responsive, SEO-ready, zero trackers.

- **`index.html`** — the main marketing landing page (1.1.1.1-inspired):
  bright, storytelling, GSAP scroll reveals + Lenis smooth scroll,
  Material Symbols icons (hidden until the font loads so the ligature
  shortcode never flashes), OS-aware "Download" button, and direct
  download buttons for Android / iPhone / Windows / macOS that point at
  the GitHub Releases **stable** filenames (`/releases/latest/download/
  BillZap-Android.apk`, etc.) so links never break across versions.
  Interlinks the dashboard at https://billzap-dashboard.netlify.app/.
- **`case-study.html`** — the original competitor case-study page.
- **`sitemap.xml`**, **`robots.txt`**, **`netlify.toml`** — SEO + hosting.

## Deploy (Netlify)
Point the site's publish directory at `landing-page/`:
```bash
netlify deploy --dir=landing-page --prod
```
`netlify.toml` already sets caching headers + a `/download` redirect.

## SEO baked in
- `<title>` + meta description tuned for "best gst billing app" et al.
- 10 focus keywords, Open Graph + Twitter cards, canonical.
- Schema.org JSON-LD: Organization + SoftwareApplication + FAQPage.
- sitemap.xml + robots.txt.

---

## (original notes — case study)

A single-file, story-driven case study for BillZap. Light mode, cream
`#F6F2E9` theme matching the app, Google Sans + Poppins, fully responsive
(mobile / tablet / laptop / desktop), SEO-ready, zero trackers.

## What's inside

- `index.html` — the entire site in one self-contained file (~96 KB).
  - Inline CSS using the same colour tokens as the Flutter app
    (`AppColors`).
  - Inline SVG icons (no external requests beyond Google Fonts).
  - Minimal vanilla-JS (~25 lines) for reveal-on-scroll. No analytics
    libraries.
  - Schema.org `SoftwareApplication` JSON-LD for richer search results.
  - OG + Twitter card meta for social sharing.

## Sections, in order

1. Sticky nav with brand mark.
2. **Hero** — headline, lede, CTAs, stat strip, animated phone mockup +
   floating UPI QR card.
3. **The Story** — Ravi's morning, with competitor failure rows and
   BillZap's win row.
4. **Three convictions** — Free forever / Offline-first /
   Vernacular-first.
5. **The feature tour** — 50+ features grouped into seven categories,
   each with its own gradient icon and reveal-on-scroll cards. New &
   coming-soon badges flagged.
6. **Comparison table** — BillZap vs. Vyapar, Tally, Pilloo AI,
   BillNeXX, Zoho Invoice. Horizontally scrollable on mobile.
7. **Personas** — Ravi (kirana), Priya (freelance), Imran (restaurant),
   Manoj (wholesale).
8. **Roadmap** — Now / Mid-2026 / Late-2026 / 2027 cards.
9. **Numbers** — 12 langs · 0 sign-ups · 100% offline · 25+ features ·
   ₹0 forever.
10. **CTA** — Download for Android.
11. Footer.

## Deploy

It's static. Drop it anywhere.

### Netlify (matches the existing billzap.netlify.app)
```bash
# from the repo root:
netlify deploy --dir=landing-page --prod
```

### Or any static host
Just upload `landing-page/index.html` (rename to `index.html` at the
site root if needed). No build step required.

### Local preview
```bash
cd landing-page && python3 -m http.server 8080
# then open http://localhost:8080
```

## Customising

- **Colours**: every colour is a CSS variable in `:root` at the top of
  the `<style>` block. Tweak there to re-skin the whole page.
- **Fonts**: `Google Sans` is loaded with fallbacks to DM Sans → Inter →
  system. Poppins is the body font. Both come from Google Fonts.
- **Copy**: section content is hand-written HTML — edit in place, no
  CMS needed.
- **New features**: each feature card is a `<div class="feature">`
  block inside `.feature-grid`. Copy one, change icon + text, drop it
  in. The `<span class="badge new">New</span>` / `<span class="badge
  soon">Soon</span>` chips already exist.

## Accessibility

- Semantic HTML5 (`<nav>`, `<section>`, `<footer>`).
- Proper heading hierarchy.
- `prefers-reduced-motion` respected — reveal-on-scroll disables for
  users who prefer no animation.
- All icons hidden from screen readers (`aria-hidden`) since the text
  label is already present.

## Performance

- ~96 KB total HTML+CSS+inline-SVG, all minified-ish (kept human-
  readable for editing).
- Two external font requests (Google Fonts). Both `preconnect`-hinted.
- No tracking, no third-party scripts.
- Lighthouse-friendly out of the box.
