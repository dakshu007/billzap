# BillZap

**Free GST billing for Indian small businesses — voice billing, UPI QR, 100% offline.**

BillZap is a free, offline-first, voice-enabled GST billing app built specifically for Indian micro and small businesses. Built in Coimbatore, Tamil Nadu, it lets a shopkeeper create a GST-compliant invoice by *speaking* — in any of 12 Indian languages — generate a UPI QR for instant payment, and share it on WhatsApp, all without an internet connection.

- **Package:** `com.billzap.app`
- **Platform:** Android (iOS planned Q3 2026)
- **Price:** Free forever — no subscription, no premium tier, no ads
- **Website:** https://billzap.netlify.app
- **Privacy:** https://billzap.netlify.app/privacy

---

## Why BillZap exists

India has ~63 million small businesses. Most still bill on paper because the existing software was built for someone else — Tally for accountants, Marg for distributors, Zoho for startups. None were built for the shopkeeper who speaks Tamil, runs a 200-square-foot shop, has an entry-level Android phone, and just wants to give a proper bill in 10 seconds.

BillZap fills that gap: everything Tally does for daily billing, in your pocket, in your language, for free.

---

## Features

### 🎙️ Voice billing in 12 Indian languages
Speak the invoice instead of typing it. Say *"Rameshku 2 kilo sugar 50 rupees, 1 packet biscuits 25 rupees"* and BillZap parses the customer, items, quantities, rates, GST, and total in under 4 seconds. Supports mixed-language commerce speech (e.g. Tamil + English), Indian unit words (dabba, peti, dozen), and Indian amount shortcuts (2k, 1.5L).

Supported languages: English, Hindi, Tamil, Telugu, Kannada, Malayalam, Marathi, Gujarati, Bengali, Punjabi, Odia, Urdu.

### 🧾 GST invoice generation
GST-compliant invoices with auto-classified HSN codes, automatic CGST/SGST/IGST calculation based on place of supply, and instant PDF generation. Same-state sales get CGST+SGST; inter-state gets IGST. Switches between Tax Invoice and Bill of Supply based on registration status.

### 📲 UPI QR on every invoice
Every invoice carries a scannable UPI QR code generated from the user's UPI ID. Customer scans, pays directly to the user's bank, invoice auto-marks as paid. No payment gateway, no commission, no settlement delay.

### 🎉 Festival greetings
17+ Indian festivals pre-loaded (Diwali, Pongal, Eid, Christmas, Holi, Onam, Ganesh Chaturthi, Baisakhi, Makar Sankranti, and more). The day before each festival, BillZap prompts the user to send greetings to recent customers in their language.

### 📊 Daily business insights
A rotating insights system surfaces useful prompts: customer birthday/anniversary reminders, slow-day alerts, top-customer reminders, low-inventory alerts, tax-filing reminders, festival countdowns.

### 🔒 App Lock (PIN + Fingerprint)
4-digit PIN plus optional biometric (fingerprint) authentication. PIN is stored as a SHA-256 hash with a unique salt — never as plain text. App auto-re-locks after 60 seconds in the background.

### 🔢 Smart amount entry
Indian-style number entry: type `1k` → ₹1,000, `2.5L` → ₹2,50,000, `5cr` → ₹5,00,00,000, `50 hazaar` → ₹50,000.

### 💾 Encrypted backups & CSV export
Create encrypted `.billzap` backup files locked with the user's PIN — store on Google Drive, email, or local storage. Export invoices, customers, and products as CSV for accountants.

### 💬 WhatsApp invoice sharing
One tap opens WhatsApp with the invoice PDF attached, a pre-formatted message in the customer's language, and the UPI link embedded.

### 📅 Day Close (cash drawer)
Mark each invoice paid via Cash, UPI, Bank, or Other. The Day Close screen shows daily collections broken down by method, with a WhatsApp-ready summary. The business day starts at 4 AM (not midnight) to match how shopkeepers think about their day.

---

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter (`3.41.6` local / `3.19.6` CI) |
| State management | Riverpod (`flutter_riverpod` 2.6.1) |
| Local database | Hive (box `billzap_v1`) |
| Routing | go_router 13.2.5 |
| Auth | local_auth 2.3.0 (biometric) + SHA-256 PIN hashing |
| PDF | printing 5.13.1 |
| Voice | speech_to_text 6.6.2 |
| QR | qr 3.0.2 |
| Sharing | share_plus 9.0.0 |
| Fonts | Plus Jakarta Sans (app), google_fonts 6.3.3 |

> **Note on storage:** PIN/security data is stored in Hive (not `flutter_secure_storage`) due to a `js` dependency conflict (`^0.7.1` vs `^0.6.3`) with `speech_to_text` 6.6.2. PIN is hashed SHA-256 with salt `billzap_app_lock_v1`.

---

## Project structure

```
lib/
├── main.dart
├── screens/
│   ├── lock/                 # PIN entry, PIN setup, biometric gate
│   ├── ...                   # home, invoice, day close, settings, etc.
├── services/
│   └── app_lock_service.dart # Hive-based PIN + biometric logic
├── widgets/
│   └── app_lock_gate.dart    # wraps app, enforces lock
└── ...
android/
├── app/
│   ├── build.gradle
│   └── src/main/res/mipmap-*/ ic_launcher.png   # PNG launcher icons
.github/
└── workflows/
    └── build.yml             # CI: builds signed AAB + APK
```

---

## Building locally

> Requires Flutter + Android SDK installed. If you don't have the Android SDK set up locally, use the GitHub Actions build below instead.

```bash
flutter pub get
flutter build appbundle --release   # AAB for Play Store
flutter build apk --release         # APK for direct install
```

Outputs:
- AAB → `build/app/outputs/bundle/release/app-release.aab`
- APK → `build/app/outputs/flutter-apk/app-release.apk`

---

## Building via GitHub Actions (recommended)

The repo includes `.github/workflows/build.yml` which builds the AAB and APK on GitHub's servers (no local Android SDK needed). It auto-increments the version build number on each run, so you never hit "version code already used" errors.

**To trigger a build:** push to `main`, or run the workflow manually from the **Actions** tab → **Build Android (AAB + APK)** → **Run workflow**.

**Artifacts:** after a successful run (~8-12 min), download from the run page:
- `app-release-aab-v<buildnumber>`
- `app-release-apk-v<buildnumber>`

### Signing for Play Store

The workflow signs the release build **only if** keystore secrets are configured. Without them it produces a debug-signed build (not Play-uploadable). Add these 4 repository secrets under **Settings → Secrets and variables → Actions**:

| Secret | Description |
|---|---|
| `KEYSTORE_BASE64` | Base64 of your `.jks` keystore (`base64 -i keystore.jks \| pbcopy`) |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_PASSWORD` | Key password |
| `KEY_ALIAS` | Key alias |

---

## Versioning

Version lives in `pubspec.yaml` as `version: 1.0.0+<buildNumber>`. The CI auto-bumps `<buildNumber>` by 1 on each run and commits it back with `[skip ci]`. Play Store version codes must always increase and can never be reused.

---

## Privacy & data

BillZap is **100% offline by default**. All data — business profile, customers, products, invoices, Day Close records — is stored locally in Hive on the device. Nothing is synced to any server. No analytics, no ads, no tracking SDKs, no account/signup.

Data leaves the device only when the user explicitly: shares an invoice (WhatsApp/email via Android share intent), backs up to Google Drive (encrypted with PIN), or generates a UPI QR (payment handled by the customer's UPI app). Voice recognition uses Android's speech service, which may use Google's servers depending on device settings.

Full policy: https://billzap.netlify.app/privacy

---

## Known issues

These are open as of the current build — being addressed:

- **Splash → onboarding:** splash screen may route straight to `/home` and skip onboarding on a fresh install. Workaround: Settings → Reset App Data.
- **Onboarding Hive box:** onboarding writes to the `settings` box instead of `billzap_v1`.
- **Onboarding field capture:** only 6 of 17 business profile fields are captured during onboarding (notably `upiId` is missed). Workaround: complete the profile in Settings → Business Profile.

---

## Roadmap

| Version | Target | Highlights |
|---|---|---|
| v1.1 | June 2026 | Inventory tracking with low-stock alerts |
| v1.2 | July 2026 | Barcode scanning; multi-device sync |
| v1.3 | August 2026 | Customer credit (udhaar/khata) management |
| v1.4 | September 2026 | Multi-shop support |
| v2.0 | Q4 2026 | iOS launch; accountant collaboration mode |

All roadmap features will remain free.

---

## Status

Currently in **closed testing** on the Google Play Store, working toward production release.

---

## Contact

- Website: https://billzap.netlify.app
- Email: daksheshbabu@gmail.com
- Made in Coimbatore · Tamil Nadu, India

---

*BillZap is provided "as is" without warranty. While it aims for accurate GST calculations and HSN suggestions, users remain responsible for verifying their invoices and tax compliance. BillZap is not a substitute for advice from a qualified chartered accountant.*
