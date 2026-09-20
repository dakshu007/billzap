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

# The date the content last actually changed — deliberately a constant,
# not the date of the build.
#
# Two reasons. A privacy policy's "last updated" is a statement about
# the policy, and it should not move because someone fixed a CSS typo.
# And the deploy workflow proves the committed index.html matches these
# sources by rebuilding and diffing it: with the build date baked in,
# that check passes on the day of the commit and fails every day after,
# blocking the deploy for a reason that has nothing to do with the
# build.
#
# Bump it when the wording changes.
UPDATED = '2026-09-16'

# Google Search Console site verification. It goes in the shared head so
# every page carries it: Search Console checks the exact URL you ask it
# to verify, and a tag that lives only on the home page silently fails
# the moment you verify a different one. Harmless everywhere else.
GSC_VERIFY = '4N5b9mUevn2OzdIqgR_kUHPo2D-JTpIfd1gN0cCx03s'

# Google Analytics 4. Loaded lazily — see SCRIPT below for why.
GA_ID = 'G-M8M91YZVCT'

# The APK. This filename never changes, so the link survives every
# version bump; release.yml is what guarantees that.
APK_URL = ('https://github.com/dakshu007/billzap/releases/latest/'
           'download/BillZap-Android.apk')

# Where the download form posts the email address.
#
# This is a Google Apps Script web app bound to the sheet — see
# ../google-sheet/README.md for the script and how to deploy it. Paste
# the /exec URL it gives you here and rebuild.
#
# Until it is set, the form still validates the address and still hands
# over the download; it just has nowhere to file the address. That is
# the right way round: a misconfigured spreadsheet must never stand
# between somebody and the app.
SHEET_ENDPOINT = ('https://script.google.com/macros/s/AKfycbyxqSup-003VXxU65Fq3dj22man'
                  'MSNqxo0aMg3UE4utJonP9_-pMe-k1B4U60tm42bX6w/exec')

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
     "Android 7.0 (Nougat) and above. The download is about 32 MB — one "
     "file that installs on any Android phone, so there is nothing to "
     "choose between."),
]


def _human(iso):
    """'2026-09-16' -> '16 September 2026', the way a policy reads."""
    return date.fromisoformat(iso).strftime('%-d %B %Y')


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
    today = UPDATED
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


# ── Privacy page ────────────────────────────────────────────────────
# A standalone policy page, not just the marketing section on the home
# page. The Play Store listing needs a stable URL for one, and /privacy
# was already a live, indexed URL before this rebuild — dropping it
# would 404 the link people arrive on.
P_TITLE = 'Privacy Policy — BillZap GST Billing App'
P_DESC = (
    'BillZap has no accounts, no server and no analytics. Your invoices '
    'stay on your phone. What each Android permission is used for, what '
    'voice billing sends, and what this website stores.'
)


def privacy_jsonld():
    today = UPDATED
    graph = [
        {
            "@type": "PrivacyPolicy",
            "@id": f"{SITE}/privacy/#policy",
            "url": f"{SITE}/privacy/",
            "name": P_TITLE,
            "description": P_DESC,
            "inLanguage": "en",
            "dateModified": today,
            "isPartOf": {"@id": f"{SITE}/#site"},
            "about": {"@id": f"{SITE}/#app"},
            "publisher": {"@id": f"{SITE}/#org"},
        },
        {
            "@type": "BreadcrumbList",
            "itemListElement": [
                {"@type": "ListItem", "position": 1, "name": "BillZap",
                 "item": f"{SITE}/"},
                {"@type": "ListItem", "position": 2, "name": "Privacy policy",
                 "item": f"{SITE}/privacy/"},
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


ICONS = icons()


def render(fragment, *, home, base=''):
    """Resolve {{ico:…}}, {{home}} and {{base}} in a markup fragment.

    Two different jobs, deliberately two placeholders:

      {{home}}  the brand link's destination — '#top' on the home page,
                '/' anywhere else.
      {{base}}  the prefix that makes a section anchor work from any
                page — '' on the home page, '/' anywhere else.

    Collapsing them into one is what produced href="#top#features",
    which is not a fragment at all, so every nav link and the header's
    download button silently did nothing.
    """
    fragment = fragment.replace('{{home}}', home).replace('{{base}}', base)

    def sub(m):
        name = m.group(1)
        if name not in ICONS:
            raise SystemExit(f'unknown icon: {name}')
        return svg(name, ICONS[name])
    return re.sub(r'\{\{ico:([a-z0-9-]+)\}\}', sub, fragment)


# The bit of progressive enhancement both pages carry. The page is
# complete and readable with it blocked: the reveal and the header
# shadow are decoration, and the download button is a plain link to the
# APK that works whether or not any of this runs.
#
# Placeholders are substituted rather than f-string interpolated —
# this is mostly braces, and doubling every one of them would make it
# unreadable.
SCRIPT_TMPL = """
(function(){
  var d=document, r=d.documentElement;
  var reduce=matchMedia('(prefers-reduced-motion: reduce)').matches;
  if('IntersectionObserver' in window && !reduce){
    r.className+=' js';
    var io=new IntersectionObserver(function(es){
      es.forEach(function(e){
        if(e.isIntersecting){ e.target.classList.add('in'); io.unobserve(e.target); }
      });
    },{rootMargin:'0px 0px -8% 0px',threshold:0.06});
    d.querySelectorAll('.rv').forEach(function(n){io.observe(n);});
  }
  var h=d.getElementById('hdr');
  var onScroll=function(){ h.classList.toggle('stuck', window.scrollY>8); };
  addEventListener('scroll',onScroll,{passive:true}); onScroll();
  var y=d.getElementById('yr'); if(y){ y.textContent=new Date().getFullYear(); }

  /* ── Analytics, kept off the critical path ──────────────────────
     gtag.js is ~100 KB of third-party JavaScript. Dropped in <head>
     the way Google's snippet does it, it competes with the page for
     the first second and costs real points on Performance. Nothing
     here needs it to render, so it loads when the browser goes idle
     or on the visitor's first interaction, whichever comes first.
     That is later than the measurement window and earlier than any
     visitor has done something worth recording. */
  var gaOn=false;
  function loadGA(){
    if(gaOn) return; gaOn=true;
    window.dataLayer=window.dataLayer||[];
    window.gtag=function(){dataLayer.push(arguments);};
    gtag('js', new Date());
    gtag('config','__GA_ID__');
    var s=d.createElement('script');
    s.async=true; s.src='https://www.googletagmanager.com/gtag/js?id=__GA_ID__';
    d.head.appendChild(s);
  }
  ['pointerdown','keydown','touchstart','scroll'].forEach(function(ev){
    addEventListener(ev, loadGA, {once:true, passive:true});
  });
  if('requestIdleCallback' in window){ requestIdleCallback(loadGA,{timeout:3500}); }
  else { setTimeout(loadGA, 2500); }

  /* ── Download gate ─────────────────────────────────────────────── */
  var APK='__APK_URL__', ENDPOINT='__SHEET__';
  var modal=d.getElementById('dlModal');
  if(!modal) return;
  var card=modal.querySelector('.modal-card'),
      form=d.getElementById('dlForm'),
      input=d.getElementById('dlEmail'),
      err=d.getElementById('dlErr'),
      go=d.getElementById('dlGo'),
      done=d.getElementById('dlDone'),
      direct=d.getElementById('dlDirect'),
      opener=null;
  direct.href=APK;

  /* Throwaway inboxes. Somebody using one will never read the update
     notes the address was asked for, so the address is worthless to
     collect and the friction is worthless to impose. */
  var BURNER=['mailinator.com','guerrillamail.com','guerrillamail.net',
    '10minutemail.com','tempmail.com','temp-mail.org','throwawaymail.com',
    'yopmail.com','fakeinbox.com','trashmail.com','sharklasers.com',
    'getnada.com','dispostable.com','maildrop.cc','mailnesia.com',
    'spam4.me','grr.la','mohmal.com','emailondeck.com','moakt.com'];

  /* Real misspellings of real providers, not a spellchecker. */
  var TYPO={'gmial.com':'gmail.com','gmai.com':'gmail.com','gmil.com':'gmail.com',
    'gnail.com':'gmail.com','gmaill.com':'gmail.com','gmail.co':'gmail.com',
    'gmail.con':'gmail.com','gmail.cm':'gmail.com','gamil.com':'gmail.com',
    'yahho.com':'yahoo.com','yaho.com':'yahoo.com','yahoo.co':'yahoo.com',
    'yahoo.con':'yahoo.com','hotmial.com':'hotmail.com','hotmai.com':'hotmail.com',
    'hotmail.co':'hotmail.com','outlok.com':'outlook.com','outloo.com':'outlook.com',
    'rediffmail.co':'rediffmail.com'};

  /* Local part may not start, end or double a dot; every domain label
     is a real label; the TLD is alphabetic. This rejects the shapes
     people actually type when they are making one up. */
  var RE=/^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,24}$/;

  function domainOf(v){ return v.slice(v.lastIndexOf('@')+1).toLowerCase(); }

  function check(v){
    if(!v) return {msg:'Enter your email address and the download will start.'};
    if(v.length>254 || !RE.test(v))
      return {msg:'That is not a complete email address — it needs a name, an @ and a domain.'};
    var dom=domainOf(v);
    if(TYPO[dom]) return {msg:'Did you mean', fix:v.slice(0,v.lastIndexOf('@')+1)+TYPO[dom]};
    if(BURNER.indexOf(dom)>-1)
      return {msg:'That is a temporary inbox, so the update notes would never reach you. Please use an address you read.'};
    return null;
  }

  function showErr(p){
    input.setAttribute('aria-invalid','true');
    if(p.fix){
      err.textContent=p.msg+' ';
      var b=d.createElement('button');
      b.type='button'; b.textContent=p.fix;
      b.addEventListener('click',function(){
        input.value=p.fix; clearErr(); input.focus();
      });
      err.appendChild(b); err.appendChild(d.createTextNode('?'));
    } else {
      err.textContent=p.msg;
    }
  }
  function clearErr(){ err.textContent=''; input.removeAttribute('aria-invalid'); }
  input.addEventListener('input', clearErr);

  function record(email){
    if(!ENDPOINT) return;
    /* text/plain keeps this a "simple" request so the browser does not
       preflight it — an Apps Script web app does not answer OPTIONS.
       no-cors makes the response opaque, which is fine: nothing waits
       on it, and the download must not depend on a spreadsheet. */
    try{
      fetch(ENDPOINT,{method:'POST',mode:'no-cors',keepalive:true,
        headers:{'Content-Type':'text/plain;charset=utf-8'},
        body:JSON.stringify({email:email,at:new Date().toISOString(),
                             source:location.hostname})});
    }catch(e){}
  }

  function fire(){
    loadGA();
    if(window.gtag) gtag('event','download',{method:'apk'});
    var a=d.createElement('a');
    a.href=APK; a.rel='noopener';
    d.body.appendChild(a); a.click(); a.remove();
  }

  form.addEventListener('submit', function(e){
    e.preventDefault();
    var v=input.value.trim();
    var p=check(v);
    if(p){ showErr(p); input.focus(); return; }
    clearErr();
    go.disabled=true;
    record(v);
    fire();
    form.hidden=true; done.hidden=false;
    direct.focus();
  });

  function onKey(e){
    if(e.key==='Escape'){ shut(); return; }
    if(e.key!=='Tab') return;
    var all=card.querySelectorAll('a[href],button:not([disabled]),input:not([disabled])');
    var vis=[].filter.call(all,function(n){ return n.offsetParent!==null; });
    if(!vis.length) return;
    var first=vis[0], last=vis[vis.length-1];
    if(e.shiftKey && d.activeElement===first){ e.preventDefault(); last.focus(); }
    else if(!e.shiftKey && d.activeElement===last){ e.preventDefault(); first.focus(); }
  }

  function show(trigger){
    opener=trigger||null;
    form.hidden=false; done.hidden=true; go.disabled=false;
    clearErr();
    modal.hidden=false;
    d.body.classList.add('modal-open');
    d.addEventListener('keydown', onKey);
    setTimeout(function(){ input.focus(); }, 40);
  }
  function shut(){
    modal.hidden=true;
    d.body.classList.remove('modal-open');
    d.removeEventListener('keydown', onKey);
    if(opener){ opener.focus(); opener=null; }
  }

  [].forEach.call(d.querySelectorAll('[data-gate]'), function(a){
    a.addEventListener('click', function(e){
      /* Let a middle-click or ctrl-click through to the real link. */
      if(e.metaKey||e.ctrlKey||e.shiftKey||e.button!==0) return;
      e.preventDefault(); show(a);
    });
  });
  [].forEach.call(modal.querySelectorAll('[data-close]'), function(n){
    n.addEventListener('click', shut);
  });
})();
"""


def script():
    return (SCRIPT_TMPL
            .replace('__GA_ID__', GA_ID)
            .replace('__APK_URL__', APK_URL)
            .replace('__SHEET__', SHEET_ENDPOINT))


def document(*, title, desc, canonical, css, ld, body, head_extra='',
             asset_prefix=''):
    """Assemble one complete HTML document.

    Both pages share the header, the footer, the inlined stylesheet and
    the script, so a change to any of them lands on both and the site
    cannot drift into looking like two sites.
    """
    home = '/' if asset_prefix else '#top'
    base = '/' if asset_prefix else ''
    shell = (render(open(os.path.join(HERE, 'header.html')).read(),
                    home=home, base=base)
             + '\n' + body + '\n'
             + render(open(os.path.join(HERE, 'footer.html')).read(),
                      home=home, base=base))
    # A page in a subdirectory cannot use the relative asset paths the
    # markup is written with, so they are rooted instead of duplicated.
    if asset_prefix:
        shell = shell.replace('"assets/', f'"{asset_prefix}assets/')
        shell = shell.replace('"site.webmanifest', f'"{asset_prefix}site.webmanifest')

    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>{title}</title>
<meta name="description" content="{desc}">
<meta name="author" content="BillZap">
<meta name="robots" content="index,follow,max-image-preview:large,max-snippet:-1">
<meta name="google-site-verification" content="{GSC_VERIFY}">
<link rel="canonical" href="{canonical}">
<meta name="theme-color" content="#F6F7F9">
<meta name="color-scheme" content="light">
{head_extra}
<link rel="icon" href="{asset_prefix}assets/icon-32.png" sizes="32x32" type="image/png">
<link rel="icon" href="{asset_prefix}assets/icon-512.png" sizes="512x512" type="image/png">
<link rel="apple-touch-icon" href="{asset_prefix}assets/icon-180.png">
<link rel="manifest" href="{asset_prefix}site.webmanifest">

<style>{css}</style>
<script type="application/ld+json">{ld}</script>
</head>
<body>
{shell}
<script>{script()}</script>
</body>
</html>
"""


INDEX_HEAD = f"""<meta name="keywords" content="{KEYWORDS}">

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

<link rel="preload" as="font" type="font/woff2" href="/assets/fonts/plus-jakarta-sans-800-latin.woff2" crossorigin>
<link rel="preload" as="font" type="font/woff2" href="/assets/fonts/poppins-400-latin.woff2" crossorigin>
<link rel="preload" as="image" href="/assets/shots/home-786.webp" imagesrcset="/assets/shots/home-393.webp 393w, /assets/shots/home-786.webp 786w" imagesizes="(max-width:940px) 78vw, 290px" fetchpriority="high">"""

PRIVACY_HEAD = f"""<meta property="og:type" content="article">
<meta property="og:site_name" content="BillZap">
<meta property="og:title" content="Privacy Policy — BillZap">
<meta property="og:description" content="No accounts, no server, no analytics. Your invoices stay on your phone.">
<meta property="og:url" content="{SITE}/privacy/">
<meta property="og:image" content="{SITE}/assets/og.png">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:image" content="{SITE}/assets/og.png">

<link rel="preload" as="font" type="font/woff2" href="/assets/fonts/plus-jakarta-sans-800-latin.woff2" crossorigin>
<link rel="preload" as="font" type="font/woff2" href="/assets/fonts/poppins-400-latin.woff2" crossorigin>"""


BLOG_HEAD_JS = r"""
export const head = ({ title, desc, canonical, image, ogType = 'website',
                       robots, keywords, css, ld }) => `<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>${title}</title>
<meta name="description" content="${attr(desc)}">
<meta name="author" content="BillZap">
${keywords ? `<meta name="keywords" content="${attr(keywords)}">` : ''}
<meta name="robots" content="${robots}">
<link rel="canonical" href="${canonical}">
<meta name="theme-color" content="#F6F7F9">
<meta name="color-scheme" content="light">
<meta name="google-site-verification" content="__GSC__">

<meta property="og:type" content="${ogType}">
<meta property="og:site_name" content="BillZap">
<meta property="og:title" content="${attr(title)}">
<meta property="og:description" content="${attr(desc)}">
<meta property="og:url" content="${canonical}">
<meta property="og:image" content="${image || '__SITE__/assets/og.png'}">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:image" content="${image || '__SITE__/assets/og.png'}">

<link rel="icon" href="/assets/icon-32.png" sizes="32x32" type="image/png">
<link rel="icon" href="/assets/icon-512.png" sizes="512x512" type="image/png">
<link rel="apple-touch-icon" href="/assets/icon-180.png">
<link rel="manifest" href="/site.webmanifest">
<link rel="preload" as="font" type="font/woff2" href="/assets/fonts/plus-jakarta-sans-800-latin.woff2" crossorigin>
<link rel="preload" as="font" type="font/woff2" href="/assets/fonts/poppins-400-latin.woff2" crossorigin>

<style>${css}</style>
${ld ? `<script type="application/ld+json">${JSON.stringify(ld)}</script>` : ''}
</head>`;

const attr = (s) => String(s ?? '').replace(/&/g, '&amp;').replace(/"/g, '&quot;')
  .replace(/</g, '&lt;').replace(/>/g, '&gt;');
"""


def main():
    css = minify_css(open(os.path.join(HERE, 'styles.css')).read())

    index_body = render(
        open(os.path.join(HERE, 'page.html')).read().replace(
            '{{faq}}', faq_html(ICONS)),
        home='#top') + '\n' + render(
        open(os.path.join(HERE, 'modal.html')).read(), home='#top')
    index_html = document(
        title=TITLE, desc=DESC, canonical=f'{SITE}/', css=css,
        ld=jsonld(), body=index_body, head_extra=INDEX_HEAD)

    privacy_body = render(
        open(os.path.join(HERE, 'privacy.html')).read().replace(
            '{{updated}}', _human(UPDATED)),
        home='/')
    privacy_html = document(
        title=P_TITLE, desc=P_DESC, canonical=f'{SITE}/privacy/', css=css,
        ld=privacy_jsonld(), body=privacy_body, head_extra=PRIVACY_HEAD,
        asset_prefix='/')

    for name, html in (('index.html', index_html),
                       ('privacy/index.html', privacy_html)):
        if '{{' in html:
            raise SystemExit(f'{name}: unreplaced placeholder ' +
                             re.search(r'\{\{[^}]*\}\}', html).group(0))

    # Subset the fonts against both finished pages, so a glyph that only
    # the policy uses is not dropped from the shared font files.
    def text_of(html):
        t = re.sub(r'<script.*?</script>', ' ', html, flags=re.S)
        t = re.sub(r'<style.*?</style>', ' ', t, flags=re.S)
        return re.sub(r'<[^>]+>', ' ', t)
    subset_fonts(text_of(index_html) + text_of(privacy_html))

    # The blog pages are rendered at request time by a Netlify
    # function, so they cannot use the build's document() — but they
    # must not look like a different website either. The header, the
    # footer and the whole stylesheet are handed over as a module the
    # function imports, generated from the same sources as everything
    # else, so a change to any of them reaches the blog on the next
    # deploy without anyone copying markup around.
    # Asset paths are rooted for the function-rendered pages. The
    # static pages sit at a known depth and can use relative paths;
    # /blog/<slug> cannot — "assets/icon-68.png" there resolves to
    # /blog/assets/icon-68.png and the logo simply fails to load.
    def rooted(markup):
        return (markup.replace('"assets/', '"/assets/')
                      .replace('"site.webmanifest', '"/site.webmanifest'))

    shell_js = (
        '// GENERATED by build/build.py — do not edit.\n'
        '// Header, footer and stylesheet, shared with the static pages\n'
        '// so /blog is the same site and not a careful imitation.\n'
        '// Asset paths are root-absolute: these are rendered at\n'
        '// /blog/<slug>, where a relative path resolves one level deep\n'
        '// and 404s.\n\n'
        'export const CSS = ' + json.dumps(css) + ';\n\n'
        'const HEADER = ' + json.dumps(rooted(
            render(open(os.path.join(HERE, 'header.html')).read(),
                   home='{{HOME}}', base='{{BASE}}'))) + ';\n'
        'const FOOTER = ' + json.dumps(rooted(
            render(open(os.path.join(HERE, 'footer.html')).read(),
                   home='{{HOME}}', base='{{BASE}}'))) + ';\n\n'
        'export const header = ({ base = "/" } = {}) =>\n'
        '  HEADER.replaceAll("{{HOME}}", base).replaceAll("{{BASE}}", base);\n'
        'export const footer = ({ base = "/" } = {}) =>\n'
        '  FOOTER.replaceAll("{{HOME}}", base).replaceAll("{{BASE}}", base);\n\n'
        + BLOG_HEAD_JS.replace('__GSC__', GSC_VERIFY).replace('__SITE__', SITE)
    )
    fn_lib = os.path.join(OUT, 'functions', 'lib')
    os.makedirs(fn_lib, exist_ok=True)
    with open(os.path.join(fn_lib, 'shell.js'), 'w') as f:
        f.write(shell_js)
    print(f'{"functions/lib/shell.js":20s} {len(shell_js)/1024:6.1f} KB')

    # llms-full.txt is a byte-identical alias of llms.txt: some
    # crawlers look for one name, some for the other, and the file is
    # already the full document. Keeping a second hand-edited copy is
    # how the two silently drift, so it is generated here and the CI
    # drift check covers it like everything else.
    llms = open(os.path.join(OUT, 'llms.txt')).read()
    with open(os.path.join(OUT, 'llms-full.txt'), 'w') as f:
        f.write(llms)
    print(f'{"llms-full.txt":20s} {len(llms)/1024:6.1f} KB  (copy of llms.txt)')

    os.makedirs(os.path.join(OUT, 'privacy'), exist_ok=True)
    for name, html in (('index.html', index_html),
                       ('privacy/index.html', privacy_html)):
        path = os.path.join(OUT, name)
        with open(path, 'w') as f:
            f.write(html)
        print(f'{name:20s} {os.path.getsize(path)/1024:6.1f} KB')
    print(f'{"css (inline, both)":20s} {len(css)/1024:6.1f} KB')


if __name__ == '__main__':
    main()
