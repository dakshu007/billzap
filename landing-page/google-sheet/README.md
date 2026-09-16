# Download email capture

The landing page asks for an email address before handing over the APK
and posts it here. This folder holds the Apps Script that files it in
the sheet.

Sheet: <https://docs.google.com/spreadsheets/d/18_La3tvRiI4ZzZTE_B85I5yNx49S1TmHyXJcEWCDJ1M/edit>

## Deploying it

1. Open the sheet → **Extensions → Apps Script**.
2. Delete whatever is in `Code.gs` and paste this folder's `Code.gs`.
3. **Deploy → New deployment → Web app**
   - *Execute as*: **Me**
   - *Who has access*: **Anyone**
4. Approve the permission prompt (it is your own sheet; the warning
   screen is normal for a script that has not been through Google's
   review — choose *Advanced → Go to …*).
5. Copy the **Web app URL**. It ends in `/exec`.
6. Put it in `landing-page/build/build.py`:

   ```python
   SHEET_ENDPOINT = 'https://script.google.com/macros/s/AKfy…/exec'
   ```

7. Rebuild and commit:

   ```bash
   cd landing-page/build && python3 build.py
   ```

Check it worked by opening the `/exec` URL in a browser: it should
answer `{"ok":true,"service":"billzap-downloads"}`.

## Re-deploying after an edit

Apps Script keeps the old code live until you say otherwise.
**Deploy → Manage deployments → edit (pencil) → Version: New version**
keeps the same URL. Creating a *new deployment* gives a different URL
and the page would still be posting to the old one.

## What gets stored

One row per person, in a `Downloads` tab:

| Timestamp | Email | Domain | Source |
|---|---|---|---|

`Domain` is split out so the addresses can be counted by provider
without picking through them. A second download by the same address
updates that row instead of adding another, so the sheet stays a list
of people rather than a list of clicks.

Nothing else is collected — no IP address, no device, no name. The
privacy policy at `/privacy/` says exactly this, and the two need to
stay in step: **if this script starts recording something new, that
page has to say so.**

## Things worth knowing

**The endpoint is public.** A web app deployed to "Anyone" is a URL
anybody can POST to, and there is no practical way around that for a
static site. `Code.gs` re-validates every address for that reason, and
the sheet holds email addresses and nothing more, so the worst case is
junk rows rather than a leak. If junk does show up, redeploy with a new
URL and update `SHEET_ENDPOINT`.

**The page never waits for this.** The browser posts `no-cors`, cannot
read the reply, and starts the download regardless. If this script is
broken, misconfigured, or not deployed at all, visitors still get the
APK — they just do not get recorded. That is the correct failure
direction and it should stay that way.

**The address is validated, not verified.** The page checks the shape
of the address and rejects known throwaway domains. It does not prove
the mailbox exists — that needs a confirmation email, which needs a
mail sender, which is a much larger thing than this. Expect a small
share of real-looking addresses that bounce.
