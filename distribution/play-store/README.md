# Google Play store listing

Everything uploaded to the Play Console listing, kept here so it can be
reviewed and regenerated rather than living only in the console.

| File | Play Console field | Spec |
| --- | --- | --- |
| `icon-512.png` | App icon | 512 × 512, 32-bit PNG |
| `feature-graphic-1024x500.png` | Feature graphic | 1024 × 500, PNG without alpha |
| `screenshots/screenshot-1.png` … `-8.png` | Phone screenshots, in this order | 1080 × 1920 (9:16) |
| `full-description.txt` | Full description | 2,218 of 4,000 characters |

Short fields:

- App name: `BillZap: GST Billing & Invoice` (30/30)
- Short description: `Free GST billing app. Make GST invoices offline, UPI QR, share PDF on WhatsApp.` (79/80)

Screenshot captions, in order: GST bill in 30 seconds · Get paid on the
spot · Your shop at a glance · Speak your bill · GST summary, ready for
GSTR-1 · Track every payment · Items, HSN and stock, saved once · Works
fully offline.

## How the screenshots were made

They are the real app, not mock-ups. `lib/main_demo.dart` starts the app
with a demo shop already set up; it is built for the web and captured at
phone resolution:

    flutter build web -t lib/main_demo.dart --no-web-resources-cdn
    # serve build/web, open each route (#/home, #/preview, #/reports …)
    # at 393 × 852 CSS px and a device scale factor of 3

Each capture is then framed with its caption at 1080 × 1920.

## Icon sources

`assets/brand/icon.svg` is the master. `icon_foreground.svg` and
`icon_background.svg` are the two adaptive-icon layers; the foreground
artwork is drawn larger because Android insets it by 16%. Launcher icons
are regenerated from the PNGs in `assets/` with:

    dart run flutter_launcher_icons
