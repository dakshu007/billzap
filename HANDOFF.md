# BillZap — handoff

**Read this first if you are a Claude Code session picking this project up
from a different account.** It is the state of play, the decisions already
made and the reasons behind them, and what is genuinely left.

Last updated: 2026-10-07 (languages round)
Working branch: `claude/loving-pasteur-nr9lz2`
Repository: `dakshu007/billzap` (Android only — see *Platform scope*)
Last green build: **260502282** — the number shows in Settings → About

---

## Start here

You have walked in on an app that shipped as an Indian GST biller and is
being taken worldwide. The work is largely done and green; what remains
is listed under *Still open*.

**Your first five minutes:**

1. `git log --oneline origin/main..HEAD` — none of it merged to `main`
   yet, and **no pull request** (the owner has not asked for one; do not
   open one unless he does). `ci: bump` commits are the build robot's.
2. Read *The single most important rule* below before touching any
   arithmetic. It is the one thing that can really hurt someone.
3. Read *The honesty constraint*. A fresh session's first instinct is to
   "finish" the tax table from memory. Do not.
4. `flutter analyze` and `flutter test` **cannot be run here** — there is
   no Flutter toolchain in the container. CI is your compiler. Push, then
   read the log. See *CI — read it, do not guess at it*.

**What the owner is doing right now:** installing each APK on his own
phone and reporting what he sees, screenshot by screenshot. He is not
reading the diff. Every round has been: he reports 3–5 things, they get
fixed, a new APK goes out. Expect that to continue, and expect at least
one of his reports to uncover something worse underneath it — that has
happened every single round so far.

**The pattern worth copying:** when he reports a bug, check whether it is
one bug or a class of them. "Albania shows Indian states" was really
three hardcoded state lists that disagreed. "The text is invisible" was
four screens at once. Both times the fix was a test that scans the
source, not a careful edit.

---

## Where the last two rounds got to

Not a changelog — the git log is that. This is what a cold session needs
to know has *already been dealt with*, so it does not redo it.

| | |
|---|---|
| **India's state list** | Held 20 of India's 37 GST jurisdictions. Goa, Chhattisgarh, Uttarakhand, Puducherry and the north-east were missing, on the field that decides CGST/SGST against IGST. All 37 now, with codes. This was hurting real users. |
| **Three state lists** | models.dart had 20, onboarding had 31, reality has 37 — all feeding tax fields. Now one source. |
| **Regions** | `lib/tax/regions.dart`, 172 of 177 countries, 2,707 entries. Gibraltar, Monaco, Macao and Vatican City are deliberately absent (single-settlement; free-text instead). |
| **Business address country** | `Business.addressCountryCode`, separate from `countryCode`. Empty means "same as where I trade". A trader registered in Singapore with premises in Malaysia has one of each. |
| **Tax rates** | Replaced from a reference PDF the owner supplied — see *The honesty constraint*. |
| **Dark mode** | Four screens painted `Colors.white` under theme-coloured text. `dark_mode_surfaces_test.dart` scans for it now. |
| **Large amounts** | Short-form ladder reaches T and lakh crore; hero figures shrink instead of truncating; the amount field caps at 12 digits (doubles lose exactness above 2^53). |
| **Voice** | Locale follows the shop's country; ~180 spoken currency words; connecting verbs no longer land in item names ("Dakshini needs 2 kg sugar" was billing an item called "Needs sugar"). Carries a **Beta** tag on the dashboard tile and the screen title, at the owner's request. |
| **Theme switch** | Only half the screen changed: screens paint from static tokens that register no dependency, so nothing rebuilt them. `PaletteScope` (lib/design/palette_scope.dart) now marks every element dirty in the frame the brightness changes, and cross-fades a snapshot of the old frame. See *Two kinds of global state* below. |
| **Languages** | 126 locales from the owner's localisation spec, a picker in the top corner of Settings (country field + searchable list), right-to-left for the nine RTL scripts. ~450 strings that were hardcoded English across every screen now go through the translation layer. See *How languages work*. |
| **Business logo** | Settings → Business → Business Profile. Picked image is shrunk to 512px PNG and stored as base64 inside the business record (so it rides in the encrypted backup). Printed top-left of the invoice PDF and the on-screen bill. |
| **UPI is rupees only** | `upiApplies(invoice)` in utils/invoice_labels.dart: the UPI QR card, the "Pay to UPI" line on the bill/PDF and the WhatsApp UPI link appear only on invoices whose country is India. An Albanian shop's bill showed "₹46.02" in its UPI QR. Converting was refused on purpose: no exchange rate an offline app could stand behind, and UPI cannot be paid without an Indian account anyway. Settings hides the UPI field outside India. |
| **Country & tax** | Moved from the About tab to the top of the Business tab, at the owner's request. |
| **Invoice screen state** | Mark paid/unpaid now shows on the open invoice at once: the screen reads the live invoice from the list, not the snapshot taken when it was opened. TOTAL DUE is no longer rounded (showed L46 above rows adding to 46.02). |
| **India leaking into other countries** | The invoice PDF printed GSTIN / HSN / a "GST" column for every country; WhatsApp put +91 in front of every number on earth; Settings showed an Indian GSTIN example under "EIN" and "+91" under Phone for a US shop; the splash said "GST Billing Made Simple"; the catalogue price field said "Price (₹)". All now follow the shop's (or the invoice's) country, and India is unchanged. |
| **CSV import** | Products, Catalog and Customers each have an import button (table icon in the app bar). A sheet shows the columns (★ = needed), a note, a copyable example and a file button, then a preview: new / skipped / bad rows by line number. Parser in `lib/utils/csv_import.dart` (pure Dart, `csv_import_test.dart`): columns by name in any order under common aliases (Item, MRP, Mobile, GSTIN…), comma/semicolon/tab, BOM, quoted fields, "1.250,50" and "1,250.50". Products go into **both** Products and Catalog; existing names are skipped, never overwritten. Customers dedupe by last-10-digits of phone, else by name. |
| **Invoice lines** | Deleting a line deleted the wrong one (rows had no keys, so state was reused by position): rows now carry `ObjectKey`. Adding a catalog item fills the untouched blank line instead of adding beside it. The existing-customer suggestion list now sits inline under the field instead of floating over the fields below. |
| **My Money** | A personal daily-expense tracker for anyone — not the shop's expenses, kept in its own Hive box `spending` (`lib/personal/`). Monthly budget; *safe to spend today* = (budget − spent before today) ÷ days left, so it does not shrink as today is spent; 80% and over-budget alerts said once at the crossing (`crossing()`); pace to month end; vs last month; no-spend days; last 7 days; by category; repeating monthly expenses (day 1–28, no back-fill of months the app was not opened); CSV export. Home screen card for it. Rides in the encrypted backup under a `spending` key; older backups without it restore as before. All arithmetic in `spending.dart`, pinned by `spending_test.dart`. Categories and payment methods are stored by id and translated at display time (`mm.cat_<id>`, `mm.method_<id>`). UPI is offered as a payment method only in India. |

---

## What this project is

A free, offline-first, voice-driven billing app for small shopkeepers.
Flutter, Riverpod 3, Hive for local storage. No backend: every invoice,
customer and setting lives on the phone, which is a product decision, not
a limitation — the users are often on metered data in a 200-square-foot
shop.

It shipped as an Indian GST app and was approved for Google Play
production. The owner then decided to take it worldwide, and **that is
the work this branch does**: making one India-shaped app into one that
bills correctly in 177 countries.

---

## The single most important rule

**Never change anybody's existing invoice totals.**

A billing app's worst possible bug is a silent wrong number, because the
shopkeeper files it with a tax authority and finds out months later. This
is why:

- `test/tax_golden_test.dart` asserts the new country-agnostic engine is
  **bit-identical** to the original India arithmetic on the same inputs.
  It is parameterised over mixed slabs, the 0.25% stone rate, the 40%
  rate, fractional quantities, thirty-line bills and amounts large enough
  to strain a double. If you touch the engine and this fails, the engine
  is wrong, not the test.
- `test/invoice_tax_split_test.dart` asserts an invoice saved by the old
  build reads back exactly as it always did, including a map written with
  the old key set.
- Stored amounts carry their own currency symbol and their own country's
  digit grouping. A rupee invoice reprinting as dirhams after the shop
  moves to Dubai would be a **forged document**, not a formatting choice.

### The shape of bug to look for

The invoice migration was careful, and the bug still got through one
layer above it. Three separate places — the Reports screen, the CSV tax
summary and the report PDF — computed total tax as:

```dart
totalCgst + totalSgst + totalIgst   // WRONG
```

That is correct in India and **silently zero everywhere else**, because
those three getters read off a split a Dubai bill does not have. A shop
could bill AED 50 of VAT a hundred times and every tax summary it
produced would say zero collected, on a document it takes to an
accountant.

The lesson generalises: **anything that names CGST, SGST or IGST
directly is India-only by construction.** Use `Invoice.totalTax` for a
total and `Invoice.taxSplit` / `Invoice.taxRows` for components.
`invoice_tax_split_test.dart` pins the invariant that makes the sum
wrong, so the next person who writes one gets a failing test rather
than a plausible-looking report.

---

## The honesty constraint, and why the code looks the way it does

The owner asked for every country's tax rules. **Every tax authority and
rate API is blocked from this environment**, so nothing here was checked
online.

**On 7 Oct 2026 the owner supplied a reference PDF** — "BillZap Global
VAT / GST / Sales Tax Reference 2026" — citing PwC Worldwide Tax
Summaries 2026, official authorities, VATupdate 2026 and TaxAtlas 2026.
`rate_table.dart` is now built from it: 176 jurisdictions, replacing
what had been recollection. It corrected several rates that were wrong
(Thailand 7→10, Estonia 22→24, Romania 19→21, Kazakhstan 12→16, Laos
7→10, Zimbabwe 15→15.5) and added jurisdictions that had none.

**The confidence level did not change, and must not.** Every row is
still `unconfirmed`, because the document itself says:

> "Do not implement this table as a universal 'one country = one tax
> rate' formula... The headline rate below is a reference starting
> point, not a substitute for a tax-determination engine."

Reduced rates, exemptions, zero-rating, thresholds and digital-services
rules are not modelled. The starting point got better; the promise the
app makes did not.

Rather than ship a table of half-remembered percentages as if it were
researched, the code carries its own confidence level:

```dart
enum TaxConfidence { verified, unconfirmed, selfDeclared }
```

| Level | Meaning | Where it comes from | What the UI does |
|---|---|---|---|
| `verified` | A person checked it against the authority | `lib/tax/profiles.dart` | Nothing — quiet |
| `unconfirmed` | Pre-filled, never checked | `lib/tax/rate_table.dart` | Tinted "confirm this rate" well; rate stays editable |
| `selfDeclared` | The shopkeeper typed it | their own settings | Nothing — it is their number, warning them would be absurd |

**Only India is `verified`**, and only because it is the arithmetic the
app has already been shipping unchanged. UAE, Saudi and Singapore have
hand-written profiles marked `unconfirmed`. Every other country (173)
has a row in the rate table, also `unconfirmed` — `rate_table_test.dart`
asserts the table covers all 176 non-Indian countries. `selfDeclared`
is now only what a shop gets when it types its own rate; the tests use
the ISO user-assigned code `ZZ` to exercise that path, because no real
country falls through any more.

**If you promote a country to `verified`, put the evidence in the commit
message.** `tax_engine_test.dart` has a test whose entire job is to fail
if a profile claims to be verified without being in the researched list.

Do not "improve" this by filling the table in from memory. The distance
between this design and a liability is exactly the notice the shopkeeper
sees.

---

## Architecture of the international work

```
lib/tax/
  tax_profile.dart     TaxProfile, TaxComponent, SupplyScope,
                       NumberGrouping, TaxConfidence,
                       kLakhCroreCountries + groupingFor()
  tax_engine.dart      The arithmetic. Pure Dart: no Flutter, no
                       storage, no clock — deliberately, so it is
                       exhaustively testable
  profiles.dart        The four researched countries + resolveProfile()
  rate_table.dart      176 standard rates, all unconfirmed
  countries.dart       177 countries, currencies, countryFlag()
  regions.dart         First-level divisions for 172 of them
  active_profile.dart  The shop's profile WITHOUT a WidgetRef
```

### Why India's states are NOT in regions.dart

`kStates` lives in `lib/models/models.dart` because each entry carries
the official GST state code in brackets — `'Tamil Nadu (33)'` — and
three things parse it back out: the intra/inter-state split in
`create_invoice_screen.dart`, `gstr1_builder.dart`, and the settings
save. A second list here could disagree with it about a number the tax
return depends on.

The format is therefore load-bearing. If you touch `kStates`, keep
`kStateMap` in step; `business_address_country_test.dart` asserts the
two agree, that all 37 jurisdictions are present, and that the retired
codes 25 and 28 stay out.

### Two countries, not one

`Business` carries both:

- `countryCode` — the tax regime the shop bills under. Set at
  onboarding, changed in Settings → Country. This is what
  `taxProfileProvider` reads.
- `addressCountryCode` — where the premises are. **Empty means "same as
  countryCode"**, which is what every profile saved before the field
  existed meant, and what it still means for almost everyone. Read it
  through `effectiveAddressCountry`, never directly.

They are separate because they are separate questions, and the owner
asked for it explicitly: a business registered in one country may trade
from another. The region picker and its label follow the *address*
country; the tax follows the *trading* country.

### Why `active_profile.dart` exists

Most of the app reads the profile through `taxProfileProvider` and should
keep doing so — that is the version Riverpod rebuilds on.

But a handful of call sites genuinely cannot hold a ref: a static bottom
sheet (`CatalogPicker.show`), a PDF builder, a formatter on the hot path
of every list row. **Those were exactly where "GST" and the rupee were
hardcoded**, because nobody had looked there. `taxProfileProvider` now
pushes into three module-level holders:

- `setActiveCurrency()` in `lib/design/money.dart` — symbol and grouping
- `setActiveProfile()` in `lib/tax/active_profile.dart` — the labels
- the i18n layer's existing language cache

This mirrors a pattern the i18n layer already used. The default is India
everywhere, so an install that never reaches the provider behaves as it
always did.

### How the tax noun follows the country

"GST" and "GSTIN" were written into a few hundred strings across twelve
languages. Re-translating every one per country is not possible and would
not be an improvement — what is wrong is not the translation, it is the
noun. So those strings carry a placeholder, filled in at lookup:

```
{tax}    -> GST, VAT, Sales Tax, Consumption Tax
{taxid}  -> GSTIN, TRN, VAT number, Tax ID
```

A translator writes `{tax} लागू करें` and a Dubai shopkeeper reading Hindi
gets "VAT लागू करें". The grammar stays the translator's; the noun stays
the country's. Substitution happens in `_fillCountry()` in
`lib/i18n/translations.dart`, applied by `tr()`, `trKey()` and
`trGlobal()`.

**Deliberately NOT placeholders:** `GSTR-1`, the GST Summary subtitle,
and `CGST`/`SGST`/`IGST`. Those are not nouns for "the tax" — they are
the names of Indian filings and Indian tax components, and renaming them
to VAT in Dubai would be nonsense. `test/i18n_placeholder_test.dart`
sweeps every key in every language under three profiles to prove no
placeholder reaches the screen as literal text, and that these keep
theirs.

### How an invoice records what it charged

`Invoice` gained three fields, all read **off the invoice** rather than
off the shop's current settings:

- `taxCountryCode` — which country's rules priced it
- `taxComponents` — the split as charged, e.g. `{'VAT': 180.0}`
- `currencySymbol` — the symbol in force when it was written

`Invoice.taxSplit` falls back to the old CGST/SGST/IGST halving when
`taxComponents` is empty, which is the only shape a pre-existing invoice
could have. `Invoice.taxRows` is the one source of truth for the preview,
the PDF, the CSV and the create screen, so none of them can disagree
about what was charged. `totalCgst`/`totalSgst`/`totalIgst` now read off
that split, so GSTR-1 keeps working unchanged and reads 0 outside India.

### How languages work

```
lib/i18n/
  translations.dart  English (the source of truth, compiled in) + lookup:
                     tr(key, ref), trGlobal(key, {args}), trCount(key, n)
  locales.dart       126 languages (id, native name, RTL, home region)
                     and the spec's country -> languages matrix
  dates.dart         uiDate(pattern, d): month/day names in the language
                     on screen, Latin digits — for screens only
assets/i18n/<id>.json  every other language, loaded when chosen
```

- **Source.** "BillZap Global Language & Localization Specification
  2026", supplied by the owner: 100 CLDR-Modern locales, 20
  country-critical ones, and a matrix of which to offer per country. The
  matrix names six more (pap, kea, ckb, ku, rm, la); they are in too.
  Two deliberate departures are written at the top of locales.dart:
  Singapore gets Simplified Chinese (the spec said Traditional), and
  India keeps Urdu, Konkani and Hindi-in-Latin in its list.
- **A language is not a country.** The picker's country field only
  filters the list. Currency, grouping and tax follow the shop's country
  (Settings → Country & tax), whatever language is on screen.
- **Strings take arguments**: `trGlobal('pv.delete_msg', {'no': n})`
  fills `{no}`. `{tax}`, `{taxid}`, `{itemcode}` and `{currency}` are
  filled from the shop's country on every lookup. Counts use
  `trCount('dc.txn', n)`, which reads `dc.txn.one` / `dc.txn.other`.
- **What is NOT translated, on purpose:** the invoice document (the
  on-screen preview of it and the PDF), the report PDF, and the CSV /
  GSTR-1 exports. They go to customers, accountants and a tax portal;
  the embedded PDF font (Inter) is Latin-only and the `pdf` package
  cannot shape Indic or Arabic script. The app's own screens, dialogs,
  snackbars, validators, WhatsApp messages and share texts all are.
- **Every translation is machine-made.** All 125 non-English files were
  written by Claude (the 11 Indian ones partly by an earlier session),
  none checked by a native speaker. The picker shows a **Beta** tag on
  every language but English and says why. `kReviewedLanguages` in
  language_picker.dart is where a language goes once someone fluent has
  signed it off.
- **Right to left** comes from `AppLocale.rtl`, applied by a
  `Directionality` in main.dart's builder — not from Material, which has
  no strings at all for Divehi or Sindhi. Material's own strings (date
  picker, copy/paste) use `materialLocaleFor()` in main.dart, falling
  back to English where Flutter has none.

### Two kinds of global state that do not rebuild anything

The colour tokens (`AppColor.*`, `AppColors.*`) and `trGlobal()` are
both module-level reads. Neither registers a dependency, so changing
the theme or the language rebuilds nothing by itself — that was the
half-switched theme. `PaletteScope` handles both: when the brightness or
the language changes it marks every element below it dirty in the same
frame. If you add a third global of this kind (a font scale, say), give
it to PaletteScope too rather than inventing another mechanism.

---

## Still open

### 0. Gemini — DROPPED BY THE OWNER

He asked about a free Gemini API for monthly tax summaries and rate
updates, was told yes to summaries / no to an LLM writing tax rates,
and on 7 Oct 2026 said: "the gemini integration is not required now,
will drop it." Do not build it unless he raises it again.

### 0b. Translations — all written, none reviewed by a native speaker

All 126 languages in `kAppLocales` have a complete file in assets/i18n
(863 strings each), so the picker no longer greys any out.
`i18n_assets_test.dart` requires every file present to be complete;
its `stillIncomplete` set is empty and should stay that way: a new
English key means adding it to every file in the same change.

They are machine translations. The least certain, by the translators'
own account: Aymara, Cherokee, Chuvash, Lower Sorbian, Fijian, Samoan,
Tongan, Bislama, Tok Pisin, Pijin, Kazakh in Arabic script (converted
from the Cyrillic file) and Cantonese Simplified (converted from the
Traditional file). Every language except English carries the Beta tag.

### 1. The discount and shipping tax base — BLOCKED ON THE OWNER

This is a real, unresolved question about Indian tax law and **it needs
an accountant, not a decision from you.**

BillZap has always taken a flat discount off **after** tax. On a ₹1,000
line at 18% with ₹100 off, that collects ₹180 of GST. Taking the discount
off **before** tax collects ₹162. The two give different liabilities for
the shopkeeper.

`AdjustmentTiming` in `tax_engine.dart` implements both and
`tax_engine_test.dart` pins both behaviours. `afterTax` is the default
**only** so that migrating to the engine changed nobody's existing
invoices — not because it is the better rule. India generally expects a
trade discount shown on the invoice to reduce the taxable value, which
points at `beforeTax`, but changing it silently alters what every future
bill collects.

**Do not flip the default on your own judgement.** Ask the owner to
confirm with their CA, then change it in a commit that says who
confirmed it.

### 2. Signing key rotation — DEFERRED BY THE OWNER

An upload key reset is pending with Google. The owner explicitly said
"leave the keystore, will do that after the approval is done".

Note that `KEYSTORE_BASE64` **is** already set, so CI signs with the
existing upload key and the build log says "Keystore decoded — release
build will be signed". What is outstanding is Google's side of the key
reset, not anything in this repository.

### 3. Nothing is merged to `main`, and that is deliberate

23 commits sit on `claude/loving-pasteur-nr9lz2`. The owner authorised a
merge once, earlier, and has not asked again since the international
work started. `build.yml` has `workflow_dispatch`, so APKs are built
from the branch directly and he has been testing from there.

**Do not merge or open a pull request unless he asks.** If he does ask
for a PR, the repository has no template; write the body as normal.

### 4. Translations need native speakers

Everything above about Beta. The most valuable next step for any
language is one fluent shopkeeper reading every screen. Known gaps that
are not translation errors:

- **Country names** are English in every language (the pickers show
  them). `countryDisplayName()` already reads `country.XX` keys from a
  language file if they exist; nobody has written them.
- **Festival greetings** are Indian festivals with greetings in the
  original twelve languages; the other 114 get the English greeting
  text (which the shopkeeper can edit before sending). The festival
  banner also still shows to shops outside India — worth asking the
  owner whether it should.
- **The UPI card** on the invoice screen and the UPI section in Settings
  show for every country, though UPI is Indian. Untouched this round.
- **Unit abbreviations** (Nos, Kg, Ltr) are stored data and feed the
  GSTR-1 unit mapping, so they are shown as stored.

### 5. Eleven taglines still say "for India"

`splash.tagline`, `onboard.welcome_sub` and `onboard.done_sub` are
country-neutral in English and still name India in the other eleven
languages. **This is on purpose**: someone reading the app in Odia or
Punjabi is in India, where the line is true, and a machine-translated
replacement would be worse than a correct sentence. If the owner starts
marketing in a non-Indian language, these need a native speaker.

### 6. Things a researched country would unlock

Not blockers, but the next real steps for any country promoted to
`verified`:

- Registration thresholds, reduced-rate categories and zero-rated goods
  are all out of scope in `rate_table.dart` — one standard rate per
  country is all it holds.
- Reverse charge and place-of-supply rules beyond India's intra/inter
  split are not modelled. `SupplyScope` has exactly two values.
- Saudi Arabia's Fatoora e-invoicing is mandatory and this app does not
  implement it. The profile's `source` string says so.

---

## Conventions that are not negotiable

### Git

- Develop, commit and push to **`claude/loving-pasteur-nr9lz2`**.
- **Never open a pull request unless the owner explicitly asks.**
- `git push -u origin <branch>`; retry network failures with backoff.
- End every commit message with the attribution lines your session's
  system reminder gives (a `Co-Authored-By:` line and a
  `Claude-Session:` link). They change between sessions; use yours.
- No model identifier anywhere in a commit, PR, code comment or any other
  pushed artifact. Chat replies only.

### CI — read it, do not guess at it

`.github/workflows/check.yml` runs on every branch and gates on:

```
flutter analyze --no-fatal-infos
flutter test
```

`--no-fatal-infos` downgrades **infos only**. Errors and warnings still
fail the build, including `unused_import` and `unused_element_parameter`.

**There is no Flutter toolchain in the cloud container**, so you cannot
run the analyzer locally. CI is your compiler. Push, then read the log —
do not assume.

Fetching a failed job's log: `gh api .../actions/jobs/<id>/logs` is
refused because GitHub redirects to blob storage. Use the
`mcp__github__get_job_logs` MCP tool with `return_content: true`, or read
`repos/{owner}/{repo}/check-runs/<id>/annotations`.

### Traps this codebase has already sprung

Each of these cost a CI round. They are all still live hazards.

- **`Symbols` is not Material Symbols.** It is a Lucide drop-in in
  `lib/theme/app_icons.dart` that keeps the old call sites. A glyph that
  exists in Material Symbols may not exist here — add it to that file.
- **`const` maps cannot be keyed by `double`** in Dart, because `double`
  overrides `==`.
- **Raw strings for any table containing `$`.** `countries.dart` holds
  currency symbols; without `r'''...'''` the `$` starts an interpolation
  and the analyzer reports "Undefined name 'U'".
- **A `bool` declared inside a `StatefulBuilder` builder resets on every
  rebuild.** This caused double-submits in five separate bottom sheets.
  Declare the flag above `showModalBottomSheet`.
- **The voice locale has been wrong twice, both times silently.** First
  it read a non-existent translation key, so every user in all twelve
  languages got `en_IN`. Then `en` still mapped to `en_IN` for
  everybody. `voiceLocaleCandidates()` is public and top-level
  specifically so it can be tested; keep it that way.
- **Money is a `double`, so above 2^53 (about 9,007 trillion) it stops
  representing every whole number.** The amount field caps at twelve
  digits for that reason. The real fix is integer minor units or a
  decimal type, which is a larger change than anything done here.
- **A surface painted `Colors.white` disappears in dark mode** — the
  text on it uses theme tokens that go near-white. It shipped in four
  places at once. `dark_mode_surfaces_test.dart` scans for it.
- **A test that picks a country to exercise the fall-through path breaks
  when the rate table grows.** It did, twice. The rate table now covers
  every country, and those tests use `ZZ`, the ISO user-assigned code,
  which can never become a real country.
- **A string literal in a widget is invisible to every language.** About
  450 of them had piled up. New text goes into `_en` in
  translations.dart and every JSON file; `i18n_keys_test.dart` fails if
  code asks for a key English does not have, and
  `i18n_assets_test.dart` fails if a file drops or invents a
  `{placeholder}`.
- **`const` around a translated string does not compile.** `const
  InputDecoration(hintText: trGlobal(...))` cost a CI round. Drop the
  `const` on the parent.
- **The static colour tokens and trGlobal() rebuild nothing on their
  own.** See *Two kinds of global state*.

---

## Platform scope

**Android only.** The owner said so explicitly: "Windows/macOS/iOS — I
don't need all this, only Android now." The iOS, macOS and Windows
workflows still exist but no longer run automatically. Do not re-enable
them.

---

## Builds and the APK

`.github/workflows/build.yml` has `workflow_dispatch`, so it can be run
on any branch:

```
gh api --method POST \
  repos/dakshu007/billzap/actions/workflows/build.yml/dispatches \
  -f ref=claude/loving-pasteur-nr9lz2
```

It runs `flutter analyze` and `flutter test` **before** building, so a
broken release stops rather than shipping. It produces, as GitHub Actions
artifacts on the run page (30-day retention):

- `app-release-aab-v<build>` — the Play Store bundle
- `app-release-apk-v<build>` — universal APK, installs on any device;
  this is the link to hand the owner for sideloading
- `app-release-apk-arm64-v<build>` — about a third the size, covers
  essentially every phone sold in years

It also auto-bumps the build number in `pubspec.yaml` and pushes a
`[skip ci]` commit. **Build numbers must only ever go up** — Play rejects
a bundle whose build number it has already seen. The bump push uses
`git pull --rebase --autostash` and now succeeds; if "Could not push the
version bump" appears in a log again, something has broken it (the step
is `continue-on-error`, so the artifacts are fine either way).

`gh` is not available in every session. The GitHub MCP tool
`actions_run_trigger` (method `run_workflow`, workflow `build.yml`, ref
the branch) dispatches the same build.

### A warning in the build log that is not a problem

**"No url found for submodule path 'actions-runner/BillZap App/...'"**
Leftover from a self-hosted runner that was once checked in. It is a
post-job cleanup warning only.

`KEYSTORE_BASE64` and its passwords **are** configured as repository
secrets, so the artifacts are release-signed, not debug-signed. The
pending item is Google's upload *key reset*, not the CI setup.

---

## Test suite

Twenty-four files. The ones that matter most to the international work:

| File | What it protects |
|---|---|
| `tax_golden_test.dart` | India's arithmetic is bit-identical under the new engine |
| `invoice_tax_split_test.dart` | Old invoices reprint unchanged; new ones carry their own split |
| `tax_engine_test.dart` | Engine arithmetic, profile well-formedness, no false `verified` |
| `validators_country_test.dart` | India's rules still reject what they rejected; no valid foreign input is refused |
| `i18n_placeholder_test.dart` | No `{tax}` ever reaches the screen; India-only names keep theirs |
| `rate_table_test.dart` | Table shape, coverage, and the fall-through countries |
| `countries_test.dart` | 177 countries exactly, unique, sorted, with flags |
| `regions_test.dart` | Place of supply lists the right country's regions |
| `dark_mode_surfaces_test.dart` | No screen paints a surface the theme cannot change |
| `voice_item_name_test.dart` | Connecting verbs do not end up in item names |
| `money_format_test.dart` | Both grouping rules, both short-form ladders |
| `voice_locale_test.dart` | Speech locale follows the shop's country |
| `business_address_country_test.dart` | All 37 Indian GST jurisdictions; the two country fields |
| `app_version_test.dart` | The About panel shows which build is installed |
| `i18n_keys_test.dart` | Every key the code looks up exists in English, counts included |
| `i18n_assets_test.dart` | Language files: real language, no stray keys, placeholders intact, nothing blank, every language complete |
| `locales_test.dart` | 126 languages, RTL set, every country has languages, the spec's rows |
| `phone_number_test.dart` | WhatsApp numbers: India unchanged, nobody else gets +91 |
| `csv_import_test.dart` | CSV parsing, loose numbers, product/customer rows, duplicate keys |
| `spending_test.dart` | My Money: month/week/today, allowance, budget states, crossing, repeating expenses |

---

## Owner context worth knowing

- Based in Coimbatore, Tamil Nadu. Builds for shopkeepers like the ones
  around him.
- Wants the app to feel premium and be a daily driver, and says so often.
  Polish is not a nice-to-have in his brief.
- Approved for Google Play production after a 14-day review.
- Writes in a hurry and expects momentum. He would rather you finish a
  whole piece and report than ask three clarifying questions.
- **But** he is the one who decides anything touching tax liability. The
  discount question above is his, not yours.
- He supplies reference documents when he wants data the app cannot
  verify itself: the tax-rate PDF, then the localisation spec. Treat
  them like the rate table — a sourced starting point, recorded with
  its provenance, not a promise.
- He ends most messages with some form of "fix these and tell me, I'll
  tell you the next". Give him a short, concrete report and an APK link,
  then stop. He does not want a plan; he wants the thing done.
- He tests on a real phone and reports by screenshot. Several of the
  best finds this project has had came from him noticing something in a
  screenshot that no test covered — the invisible text, the Japanese
  state list, the overflowing total. Take his screenshots seriously and
  look at the parts he did not mention: the "Needs sugar" item name was
  sitting in one of them, unremarked.
- When you have to tell him something cannot be done the way he asked —
  the Gemini rate updates, the unverifiable rates — say it in a sentence,
  give him the nearest thing that is safe, and move on. He takes a
  straight answer well. He does not take padding well.

---

## If you change one thing in this file, change this

Keep it current. It has already been wrong once in a way that would have
cost the next session real time: it said CI produced a debug-signed APK
when the signing secrets were in fact configured, which would have sent
someone off to set up something already done. Anything here that you
discover is stale is worth a commit on its own.
