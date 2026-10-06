# BillZap — handoff

**Read this first if you are a Claude Code session picking this project up
from a different account.** It is the state of play, the decisions already
made and the reasons behind them, and what is genuinely left.

Last updated: 2026-10-06
Working branch: `claude/loving-pasteur-nr9lz2`
Repository: `dakshu007/billzap` (Android only — see *Platform scope*)

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
rate API is blocked from this environment**, so not a single rate in this
repository has been verified against a primary source.

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
hand-written profiles marked `unconfirmed`. 155 more countries come from
the rate table, also `unconfirmed`. The remaining fourteen have nothing
to pre-fill and fall through to `selfDeclared`, which is the only
truthful answer for them.

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
  rate_table.dart      159 pre-filled standard rates, all unconfirmed
  countries.dart       177 countries, currencies, countryFlag()
  active_profile.dart  The shop's profile WITHOUT a WidgetRef
```

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

---

## Still open

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

### 3. Eleven taglines still say "for India"

`splash.tagline`, `onboard.welcome_sub` and `onboard.done_sub` are
country-neutral in English and still name India in the other eleven
languages. **This is on purpose**: someone reading the app in Odia or
Punjabi is in India, where the line is true, and a machine-translated
replacement would be worse than a correct sentence. If the owner starts
marketing in a non-Indian language, these need a native speaker.

### 4. Things a researched country would unlock

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
- End every commit message with:
  ```
  Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_<id>
  ```
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
- **A test that picks a country to exercise the fall-through path breaks
  when the rate table grows.** `rate_table_test.dart` now asserts that
  the five countries those tests rely on have no table row, so the
  breakage is a clear message rather than a test that quietly stops
  checking anything.

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
a bundle whose build number it has already seen.

### Two warnings in the build log that are not problems

Do not chase either of these; both are expected and the artifacts are
unaffected.

- **"Could not push the version bump."** The `flutter build` steps
  rewrite `android/gradle.properties`, so the bump commit's rebase hits
  "You have unstaged changes" and gives up. The step is
  `continue-on-error` precisely for this, and the APK and AAB are
  already uploaded by the time it runs. The build number in `pubspec.yaml`
  on the branch is therefore sometimes one behind the artifact name.
- **"No url found for submodule path 'actions-runner/BillZap App/...'"**
  Leftover from a self-hosted runner that was once checked in. It is a
  post-job cleanup warning only.

`KEYSTORE_BASE64` and its passwords **are** configured as repository
secrets, so the artifacts are release-signed, not debug-signed. The
pending item is Google's upload *key reset*, not the CI setup.

---

## Test suite

Thirteen files. The ones that matter most to the international work:

| File | What it protects |
|---|---|
| `tax_golden_test.dart` | India's arithmetic is bit-identical under the new engine |
| `invoice_tax_split_test.dart` | Old invoices reprint unchanged; new ones carry their own split |
| `tax_engine_test.dart` | Engine arithmetic, profile well-formedness, no false `verified` |
| `validators_country_test.dart` | India's rules still reject what they rejected; no valid foreign input is refused |
| `i18n_placeholder_test.dart` | No `{tax}` ever reaches the screen; India-only names keep theirs |
| `rate_table_test.dart` | Table shape, coverage, and the fall-through countries |
| `countries_test.dart` | 177 countries exactly, unique, sorted, with flags |
| `money_format_test.dart` | Both grouping rules, both short-form ladders |
| `voice_locale_test.dart` | Speech locale follows the shop's country |

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
