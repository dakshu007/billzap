# BillZap on iPhone — build & install guide

The Flutter codebase already runs on iOS. The CI job
`.github/workflows/ios-build.yml` builds an **unsigned `.ipa`** on every
relevant push, which proves the app compiles and gives you a bundle to
sign.

But iOS — unlike macOS and Windows — **will not run an unsigned app**.
To get BillZap onto your actual iPhone you must sign it with *your* Apple
account. Pick whichever path fits.

---

## Path A — Free, your iPhone only (Mac + Xcode, no $99)

Best when you just want to test on your own phone and have a Mac.

1. Install **Xcode** from the Mac App Store (free, ~15 GB).
2. In Terminal at the repo root:
   ```bash
   flutter pub get
   cd ios && pod install && cd ..
   open ios/Runner.xcworkspace
   ```
3. In Xcode: select the **Runner** target → **Signing & Capabilities** →
   check **Automatically manage signing** → choose your personal Apple ID
   team (add your Apple ID under Xcode → Settings → Accounts if needed).
4. Plug your iPhone in via USB. Enable **Developer Mode** on the phone
   (Settings → Privacy & Security → Developer Mode) when prompted.
5. Pick your iPhone as the run target and press **▶ Run**
   (or `flutter run --release -d <your-iphone>`).
6. The app installs. **Caveat:** a free Apple ID signing certificate
   expires after **7 days** — re-run step 5 to reinstall when it lapses.

## Path B — Apple Developer Program ($99/yr), share with anyone

Best when you want TestFlight, no expiry, or App Store release.

1. Enrol at <https://developer.apple.com/programs/> ($99/year).
2. In Xcode, select your paid team under Signing & Capabilities.
3. **Archive**: Xcode → Product → Archive → Distribute App →
   **TestFlight & App Store** (or **Ad Hoc** for direct `.ipa`).
4. Upload to **App Store Connect** → TestFlight. Install the TestFlight
   app on your iPhone and accept the invite. No expiry, auto-updates.

Once enrolled, the CI can sign automatically too — add these repo
secrets and I'll wire a signed-export step into `ios-build.yml`:
`BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD`,
`PROVISIONING_PROFILE_BASE64`, `APPLE_TEAM_ID`, `KEYCHAIN_PASSWORD`.

## Path C — Sideload the unsigned CI .ipa (no Mac)

Use **AltStore** or **Sideloadly** on a Windows/Mac PC to re-sign the
CI's unsigned `.ipa` with your free Apple ID and push it to your phone.
Same 7-day expiry as Path A, and it's a grey area Apple periodically
tightens — only if Path A isn't possible.

---

## What works on iOS

Everything the Android app does — iOS is a first-class mobile target:

- ✅ Voice Bill (speech_to_text supports iOS; mic + speech permission
  strings are in `Info.plist`)
- ✅ App Lock with **Face ID / Touch ID** (local_auth; `NSFaceIDUsageDescription` set)
- ✅ UPI QR + deep links to PhonePe / GPay / Paytm / BHIM
  (`LSApplicationQueriesSchemes` set)
- ✅ PDF generate / print / share, CSV + GSTR-1 JSON export
- ✅ The **Liquid Glass floating bottom menu** (iOS-only treatment)
- ✅ 12 languages, dark/light, festival banners, everything else

## iOS-specific UI

iPhone gets a **floating Liquid Glass bottom navigation bar**
(`lib/widgets/liquid_glass_nav.dart`): a frosted capsule that blurs the
content scrolling behind it, with a spring-animated "liquid" indicator
that snaps between tabs and a glowing centre Create button. Android keeps
its docked cream nav; macOS/Windows use the glass sidebar.
