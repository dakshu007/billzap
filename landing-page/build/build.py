#!/usr/bin/env python3
"""
Builds landing-page/index.html from build/page.html + build/styles.css.

Why a build step for a static page:

  • The CSS is inlined into a <style> block. A stylesheet <link> is
    render-blocking, and at this size inlining is strictly faster than a
    second round trip — it is the difference between a 100 and a 94 on
    Lighthouse's first-paint metrics.
  • Lucide icons are inlined as SVG from the real package. An icon font
    costs a render-blocking request and flashes its ligature shortcodes;
    a sprite costs a fetch. Inline SVG costs nothing and inherits colour.
  • The FAQ is written once here and emitted twice — as <details> markup
    for people, and as FAQPage JSON-LD for search engines and AI
    crawlers — so the two can never drift apart.

Run:  python3 build.py       (from landing-page/build)
"""
import json
import re
import os
from datetime import date

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..')

SITE = 'https://billzap.netlify.app'

# ── SEO ─────────────────────────────────────────────────────────────
# Focus keyword:      free GST billing app
# Primary keywords:   GST billing app, offline billing app,
#                     GST invoice app India
# Secondary:          UPI QR invoice, voice billing app, GSTR-1 export,
#                     billing app for small business, tax invoice app
TITLE = 'Free GST Billing App for Indian Shops — Offline Invoices | BillZap'
DESC = (
    'BillZap is a free GST billing app that works offline. Make a tax '
    'invoice in 30 seconds, put a UPI QR on it, share the PDF on '
    'WhatsApp, and export a GSTR-1 summary. 12 Indian languages, no '
    'sign-up, no subscription.'
)
KEYWORDS = (
    'free gst billing app, gst billing app, offline billing app, '
    'gst invoice app india, upi qr invoice, voice billing app, '
    'gstr-1 export, billing app for small business, tax invoice app, '
    'gst software for shops'
)

FAQ = [
    ("Is BillZap really free?",
     "Yes. There is no paid tier, no trial that expires and no cap on how "
     "many invoices you can make. The app you install is the whole app."),
    ("Does it work without internet?",
     "Completely. Every invoice, customer, product and expense is stored "
     "on the phone itself. You can bill all day with the network off and "
     "nothing is queued up waiting to sync."),
    ("Are the invoices GST compliant?",
     "They carry your GSTIN, the buyer's GSTIN, HSN or SAC codes per line, "
     "the GST rate on each item, and the tax split shown separately as "
     "CGST and SGST or as IGST. Place of supply decides which split "
     "applies, and the app tells you which one it has picked before you "
     "save."),
    ("Do I need to create an account?",
     "No. There is no sign-up, no phone number and no email. Open the app "
     "and start billing. Because there is no account there is also no "
     "server holding your books."),
    ("Can I send the bill on WhatsApp?",
     "Yes — the invoice becomes a clean PDF with your shop's name on it, "
     "shared in two taps. If the bill is unpaid the message includes a UPI "
     "payment link as well."),
    ("How does the UPI QR work?",
     "Put your UPI ID in settings once. Every unpaid invoice then carries "
     "a QR code the customer scans with any UPI app to pay you directly. "
     "The money goes straight to your bank; BillZap is not in the middle "
     "of the payment."),
    ("What is voice billing?",
     "Speak the item and the amount in your own language and the invoice "
     "fills itself in, so your hands can stay on the goods. It understands "
     "all twelve of the languages the app is translated into."),
    ("Can my accountant get what they need?",
     "Yes. Export a month-by-month GST summary laid out for GSTR-1, a "
     "profit and loss statement, a revenue report and an invoice status "
     "report — as PDF, or as CSV they can open in a spreadsheet."),
    ("What happens if I change phones?",
     "Take a backup from settings — it is a single file you keep — and "
     "restore it on the new phone. Your invoices, customers, products and "
     "expenses come back."),
    ("Which Android versions are supported?",
     "Android 7.0 (Nougat) and above. The download is about 13 MB for the "
     "version matched to your phone."),
]


def icons():
    with open(os.path.join(HERE, 'lucide.json')) as f:
        return json.load(f)


def svg(name, inner):
    """A Lucide glyph as inline SVG.

    aria-hidden throughout: every icon on this page sits beside its own
    text label, so announcing it again is noise for a screen reader.
    """
    return (
        f'<svg class="ico" viewBox="0 0 24 24" fill="none" '
        f'stroke="currentColor" stroke-width="2" stroke-linecap="round" '
        f'stroke-linejoin="round" aria-hidden="true" focusable="false">'
        f'{inner}</svg>'
    )


def faq_html(ic):
    chev = svg('chevron-down', ic['chevron-down'])
    out = []
    for q, a in FAQ:
        out.append(
            f'<details><summary>{q}{chev}</summary>'
            f'<p class="a">{a}</p></details>'
        )
    return '\n        '.join(out)


def jsonld():
    today = date.today().isoformat()
    graph = [
        {
            "@type": "SoftwareApplication",
            "@id": f"{SITE}/#app",
            "name": "BillZap",
            "applicationCategory": "BusinessApplication",
            "applicationSubCategory": "Invoicing and GST billing",
            "operatingSystem": "Android 7.0+",
            "description": DESC,
            "url": SITE,
            "image": f"{SITE}/assets/og.png",
            "inLanguage": ["en", "hi", "ta", "te", "kn", "ml", "mr", "gu",
                           "bn", "pa", "or", "ur"],
            "offers": {
                "@type": "Offer",
                "price": "0",
                "priceCurrency": "INR",
                "availability": "https://schema.org/InStock",
            },
            "featureList": [
                "GST tax invoices with HSN and SAC codes",
                "Automatic CGST, SGST and IGST split by place of supply",
                "Works fully offline with no account",
                "UPI QR code on every unpaid invoice",
                "Voice billing in 12 Indian languages",
                "PDF invoices shared to WhatsApp",
                "GSTR-1 ready GST summary export",
                "Profit and loss and revenue reports",
                "Product catalogue with low stock alerts",
                "Day close cash drawer reconciliation",
                "App lock with PIN or fingerprint",
                "Local backup and restore",
            ],
            "isAccessibleForFree": True,
        },
        {
            "@type": "Organization",
            "@id": f"{SITE}/#org",
            "name": "BillZap",
            "url": SITE,
            "logo": f"{SITE}/assets/icon-512.png",
        },
        {
            "@type": "WebSite",
            "@id": f"{SITE}/#site",
            "url": SITE,
            "name": "BillZap",
            "description": DESC,
            "publisher": {"@id": f"{SITE}/#org"},
            "inLanguage": "en",
        },
        {
            "@type": "WebPage",
            "@id": f"{SITE}/#page",
            "url": SITE,
            "name": TITLE,
            "description": DESC,
            "isPartOf": {"@id": f"{SITE}/#site"},
            "about": {"@id": f"{SITE}/#app"},
            "dateModified": today,
            "primaryImageOfPage": f"{SITE}/assets/og.png",
        },
        {
            "@type": "FAQPage",
            "@id": f"{SITE}/#faq",
            "mainEntity": [
                {
                    "@type": "Question",
                    "name": q,
                    "acceptedAnswer": {"@type": "Answer", "text": a},
                }
                for q, a in FAQ
            ],
        },
        {
            "@type": "HowTo",
            "@id": f"{SITE}/#howto",
            "name": "How to make a GST invoice in BillZap",
            "totalTime": "PT1M",
            "step": [
                {"@type": "HowToStep", "position": 1,
                 "name": "Add your shop",
                 "text": "Enter your business name, GSTIN and UPI ID in "
                         "settings. Every invoice afterwards carries them."},
                {"@type": "HowToStep", "position": 2,
                 "name": "Make the bill",
                 "text": "Pick the customer and add the items. GST is "
                         "applied per item and the total updates as you go."},
                {"@type": "HowToStep", "position": 3,
                 "name": "Get paid",
                 "text": "Show the UPI QR code or share the PDF on "
                         "WhatsApp, then mark the invoice paid."},
            ],
        },
    ]
    return json.dumps({"@context": "https://schema.org", "@graph": graph},
                      separators=(',', ':'), ensure_ascii=False)


SRC_FONTS = {
    'plus-jakarta-sans-600-latin.woff2': 'Jakarta 600',
    'plus-jakarta-sans-700-latin.woff2': 'Jakarta 700',
    'plus-jakarta-sans-800-latin.woff2': 'Jakarta 800',
    'poppins-400-latin.woff2': 'Poppins 400',
    'poppins-500-latin.woff2': 'Poppins 500',
}


def subset_fonts(page_text):
    """Cut each font down to the glyphs this page actually sets.

    Google's own "latin" subset is ~27 KB per weight because it covers
    every Western European language. This page is English, and the
    largest-contentful-paint element is a paragraph of it, so those
    bytes sit directly on the critical path. Subsetting to the glyphs
    present in the markup takes the five faces from 98 KB to a few KB.

    The Indian-language names in the languages section are deliberately
    outside this set — they fall back to the system's own Devanagari,
    Tamil and Arabic faces, which render them better than a Latin
    webfont ever could.
    """
    try:
        from fontTools import subset as ftsubset
    except ImportError:
        print('  ! fonttools not installed — copying fonts unsubsetted')
        for f in SRC_FONTS:
            src = os.path.join(HERE, 'fonts-src', f)
            dst = os.path.join(OUT, 'assets', 'fonts', f)
            if os.path.exists(src):
                open(dst, 'wb').write(open(src, 'rb').read())
        return

    # Everything the page sets, plus printable ASCII so a later copy
    # edit cannot silently lose a glyph.
    chars = set(page_text)
    chars |= set(chr(c) for c in range(0x20, 0x7F))
    chars |= set('\u2018\u2019\u201c\u201d\u2013\u2014\u2026\u00b7\u20b9\u00a0\u00d7')
    chars = {c for c in chars if ord(c) < 0x2200}
    text = ''.join(sorted(chars))

    total_before = total_after = 0
    for f in SRC_FONTS:
        src = os.path.join(HERE, 'fonts-src', f)
        dst = os.path.join(OUT, 'assets', 'fonts', f)
        if not os.path.exists(src):
            continue
        before = os.path.getsize(src)
        args = ftsubset.Options()
        args.flavor = 'woff2'
        args.layout_features = ['kern', 'liga', 'calt', 'ccmp', 'locl', 'mark', 'mkmk']
        args.desubroutinize = True
        args.notdef_outline = False
        args.recalc_bounds = True
        args.drop_tables += ['DSIG']
        font = ftsubset.load_font(src, args)
        subsetter = ftsubset.Subsetter(options=args)
        subsetter.populate(text=text)
        subsetter.subset(font)
        ftsubset.save_font(font, dst, args)
        font.close()
        after = os.path.getsize(dst)
        total_before += before
        total_after += after
        print(f'  {f:40s} {before/1024:6.1f} -> {after/1024:5.1f} KB')
    print(f'  {"fonts total":40s} {total_before/1024:6.1f} -> '
          f'{total_after/1024:5.1f} KB')


def minify_css(css):
    css = re.sub(r'/\*.*?\*/', '', css, flags=re.S)
    css = re.sub(r'\s+', ' ', css)
    css = re.sub(r'\s*([{};:,>~])\s*', r'\1', css)
    css = re.sub(r';}', '}', css)
    return css.strip()


def main():
    ic = icons()
    page = open(os.path.join(HERE, 'page.html')).read()
    css = minify_css(open(os.path.join(HERE, 'styles.css')).read())

    page = page.replace('{{faq}}', faq_html(ic))

    def sub(m):
        name = m.group(1)
        if name not in ic:
            raise SystemExit(f'unknown icon: {name}')
        return svg(name, ic[name])
    page = re.sub(r'\{\{ico:([a-z0-9-]+)\}\}', sub, page)

    if '{{' in page:
        raise SystemExit('unreplaced placeholder: ' +
                         re.search(r'\{\{[^}]*\}\}', page).group(0))

    html = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>{TITLE}</title>
<meta name="description" content="{DESC}">
<meta name="keywords" content="{KEYWORDS}">
<meta name="author" content="BillZap">
<meta name="robots" content="index,follow,max-image-preview:large,max-snippet:-1">
<link rel="canonical" href="{SITE}/">
<meta name="theme-color" content="#F6F7F9">
<meta name="color-scheme" content="light">

<meta property="og:type" content="website">
<meta property="og:site_name" content="BillZap">
<meta property="og:title" content="BillZap — Free GST Billing App That Works Offline">
<meta property="og:description" content="Make a GST tax invoice in 30 seconds with no internet. UPI QR on every bill, PDF to WhatsApp, GSTR-1 export. 12 Indian languages. Free forever.">
<meta property="og:url" content="{SITE}/">
<meta property="og:image" content="{SITE}/assets/og.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:image:alt" content="BillZap — free GST billing for Indian shops">
<meta property="og:locale" content="en_IN">

<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="BillZap — Free GST Billing App That Works Offline">
<meta name="twitter:description" content="GST invoices in 30 seconds, offline. UPI QR on every bill. 12 Indian languages. Free forever.">
<meta name="twitter:image" content="{SITE}/assets/og.png">

<link rel="icon" href="assets/icon-32.png" sizes="32x32" type="image/png">
<link rel="icon" href="assets/icon-512.png" sizes="512x512" type="image/png">
<link rel="apple-touch-icon" href="assets/icon-180.png">
<link rel="manifest" href="site.webmanifest">

<link rel="preload" as="font" type="font/woff2" href="assets/fonts/plus-jakarta-sans-800-latin.woff2" crossorigin>
<link rel="preload" as="font" type="font/woff2" href="assets/fonts/poppins-400-latin.woff2" crossorigin>
<link rel="preload" as="image" href="assets/shots/home-786.webp" imagesrcset="assets/shots/home-393.webp 393w, assets/shots/home-786.webp 786w" imagesizes="(max-width:940px) 78vw, 290px" fetchpriority="high">

<style>{css}</style>
<script type="application/ld+json">{jsonld()}</script>
</head>
<body>
{page}
<script>
/* Progressive enhancement only. The page is complete and readable with
   this script blocked; it adds the scroll reveal and the header's
   shadow, nothing more. `js` is set first so the reveal styles only
   apply when something can un-apply them. */
(function(){{
  var d=document, r=d.documentElement;
  var reduce=matchMedia('(prefers-reduced-motion: reduce)').matches;
  if('IntersectionObserver' in window && !reduce){{
    r.className+=' js';
    var io=new IntersectionObserver(function(es){{
      es.forEach(function(e){{
        if(e.isIntersecting){{ e.target.classList.add('in'); io.unobserve(e.target); }}
      }});
    }},{{rootMargin:'0px 0px -8% 0px',threshold:0.06}});
    d.querySelectorAll('.rv').forEach(function(n){{io.observe(n);}});
  }}
  var h=d.getElementById('hdr');
  var onScroll=function(){{ h.classList.toggle('stuck', window.scrollY>8); }};
  addEventListener('scroll',onScroll,{{passive:true}}); onScroll();
  d.getElementById('yr').textContent=new Date().getFullYear();
}})();
</script>
</body>
</html>
'''
    # Subset the fonts against the finished markup, so the glyph set is
    # derived from the page rather than guessed at.
    text_only = re.sub(r'<script.*?</script>', ' ', html, flags=re.S)
    text_only = re.sub(r'<style.*?</style>', ' ', text_only, flags=re.S)
    text_only = re.sub(r'<[^>]+>', ' ', text_only)
    subset_fonts(text_only)

    with open(os.path.join(OUT, 'index.html'), 'w') as f:
        f.write(html)
    size = os.path.getsize(os.path.join(OUT, 'index.html'))
    print(f'index.html  {size/1024:.1f} KB  (css {len(css)/1024:.1f} KB inline)')


if __name__ == '__main__':
    main()
