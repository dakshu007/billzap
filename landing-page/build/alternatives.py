"""The /alternatives/ pages: BillZap compared with one other app each.

Imported by build.py, which owns the document shell; this file only
holds what the pages say and how it is laid out.

The rule for everything in here: a claim about another app is one we
could check on that app's own site on CHECKED, and the page says where
it came from. Prices change and offers end, so every price is given as
"at the time of checking" with the source linked, and a row we could
not verify is left out of the table rather than guessed at. Each page
also says plainly where the other app is the better choice — someone
who needs e-way bills on three devices should not install BillZap, and
a page that pretends otherwise ranks for a while and then converts
nobody.
"""
import html
import json
import re

CHECKED = '2026-10-16'
CHECKED_HUMAN = '16 October 2026'

# The BillZap column, written once so every page states the same facts
# the same way.
US = {
    'price': 'Free. No paid tier, no trial, no invoice cap',
    'offline': 'Not needed. Billing, reports and storage all run on the phone',
    'account': 'None. No phone number, OTP or email',
    'data': 'On your phone, with a backup file you keep',
    'platforms': 'Android 7.0 and above',
    'devices': 'One phone. Move to a new one with a backup file',
    'gst': 'Both GSTINs, HSN/SAC per line, CGST + SGST or IGST from the place of supply',
    'gstr1': 'Month-wise GST summary as PDF or CSV',
    'upi': 'UPI QR printed on every unpaid invoice',
    'voice': 'Speak the bill in 12 Indian languages',
    'einv': 'Not built in',
    'accounts': 'Revenue, GST, cash-basis P&L and day close. Not double-entry accounting',
    'users': 'One user per phone',
}

ALTS = [
    # ── Vyapar ─────────────────────────────────────────────────────
    {
        'slug': 'vyapar',
        'name': 'Vyapar',
        'title': 'Vyapar Alternative: Free Offline GST Billing App | BillZap',
        'desc': ('Looking for a Vyapar alternative? BillZap is a free GST '
                 'billing app with no paid tier, no account and no internet '
                 'needed. An honest side-by-side, prices checked Oct 2026.'),
        'keywords': ('vyapar alternative, free vyapar alternative, vyapar vs '
                     'billzap, vyapar free version limits, offline gst billing app'),
        'h1': 'Looking for a Vyapar alternative?',
        'lead': (
            'BillZap is the free alternative for shops that mainly need '
            'GST bills at the counter. It has no paid tier at all, needs no '
            'account, and works with the internet switched off. Vyapar does '
            'more — desktop, inventory accounting, e-way bills — and charges '
            'for most of it. If you use those parts, stay. If you mostly '
            'make bills, read on.'),
        'pick_us': [
            'You want every feature free, permanently, with no plan to upgrade to.',
            'You bill from one phone at the counter and do not need a desktop app.',
            'You want a UPI QR on every unpaid bill without paying for it.',
            'You or your staff would rather speak the bill in Hindi, Tamil or another Indian language than type it.',
            'You want no account and no data on anyone else’s server.',
        ],
        'pick_them': [
            'You need e-invoicing or e-way bills. BillZap does neither.',
            'You run billing on a Windows desktop as well as a phone.',
            'You want a full accounting module, party-wise P&L or Tally export.',
            'You manage more than one company from the same app.',
        ],
        'rows': [
            ('Price', 'A free version, plus paid plans. Desktop + Mobile Silver was ₹3,959.10 for one year at the time of checking (list price ₹7,499); Gold ₹4,319.10 (list ₹9,099)', US['price'], 'us'),
            ('Free version', 'Limited to a single device, per Vyapar’s own free-vs-paid page', 'The whole app, on one phone', None),
            ('Works with no internet', 'Vyapar describes itself as offline-first', US['offline'], None),
            ('Platforms', 'Android and Windows desktop', US['platforms'], 'them'),
            ('E-way bills', '10 a month on Silver, unlimited on Gold', US['einv'], 'them'),
            ('E-invoicing (IRN)', 'Supported', US['einv'], 'them'),
            ('Accounting and Tally export', 'Accounting module and Tally export on Gold', US['accounts'], 'them'),
            ('Companies', '3 on Silver, 5 on Gold', 'One business', 'them'),
            ('UPI QR on the bill', 'Check Vyapar’s current plan', US['upi'], None),
            ('Voice billing', 'Not a listed feature on the plans we checked', US['voice'], 'us'),
        ],
        'why': [
            ('The useful parts sit behind a subscription',
             'Vyapar’s free version is a real starting point, but it is '
             'limited to a single device, and the features most growing shops '
             'reach for — desktop, more companies, e-way bills, the accounting '
             'module — are on the paid plans. The first-year prices on the plans '
             'page are offer prices; the list prices are roughly double.'),
            ('It is more software than a counter needs',
             'Vyapar is built to be a small business’s whole back office: '
             'billing, stock, accounts, reports, multiple firms. That is a '
             'strength if you use it. For a shop where the job is “make the '
             'bill, take the payment, send the PDF”, every extra screen is '
             'something to learn and something the staff can press by mistake.'),
            ('Staff who do not type quickly in English',
             'Most billing apps assume someone typing item names into a form. '
             'BillZap lets the person at the counter say “do kilo cheeni, sau '
             'rupaye” and fills the line in, in any of twelve Indian languages.'),
        ],
        'diff': [
            ('No tiers to compare', 'There is one version of BillZap and it is free. Unlimited invoices, the GSTR-1 summary, UPI QR codes, reports, voice billing and backup are all in it. There is no plan page because there are no plans.'),
            ('Offline as a fact, not a mode', 'Your books live in the app’s storage on the phone. There is no sync queue waiting for a signal, so a basement shop with no bars bills exactly like a shop on fibre.'),
            ('The tax split, shown before you save', 'BillZap picks CGST + SGST or IGST from the place of supply and tells you which one it chose on the invoice screen, so a wrong split is caught before the bill exists.'),
            ('Getting paid on the spot', 'Every unpaid invoice carries a UPI QR for your own UPI ID. The customer scans it with any UPI app and the money goes straight to your bank; BillZap is never in the middle.'),
        ],
        'better': (
            'Vyapar is the better choice when billing is one part of a bigger '
            'operation. If you generate e-way bills, need IRNs on B2B invoices, '
            'keep your stock and accounts in the same app, run a Windows counter '
            'PC, or look after several companies, Vyapar covers that and BillZap '
            'does not. Paying for that is reasonable. BillZap is for the shops that '
            'are paying for it and using none of it.'),
        'faq': [
            ('Is BillZap really a free alternative to Vyapar?',
             'Yes. BillZap has no paid version, no trial period and no limit on '
             'invoices. Vyapar has a free version limited to one device and paid '
             'plans for its desktop, e-way bill and accounting features.'),
            ('Can I move my Vyapar data into BillZap?',
             'There is no direct import. Most shops keep Vyapar for their past '
             'records and start a new invoice series in BillZap from the first day '
             'of a month, adding regular items and customers as they come up.'),
            ('Does BillZap do e-way bills or e-invoicing like Vyapar?',
             'No. BillZap makes GST tax invoices with the correct CGST, SGST or IGST '
             'split, HSN codes and a GSTR-1 summary, but it does not generate e-way '
             'bills or e-invoice IRNs. If you need those, Vyapar or another tool '
             'that supports them is the right choice.'),
            ('Does BillZap work on a computer like Vyapar desktop?',
             'No. BillZap is an Android app for phones and tablets running Android '
             '7.0 or later. There is no Windows version.'),
        ],
        'sources': [
            ('Vyapar pricing', 'https://vyaparapp.in/pricing'),
            ('Vyapar: free vs paid', 'https://vyaparapp.in/blog/vyapar-free-vs-paid-mobile-app/'),
            ('Vyapar e-invoicing', 'https://vyaparapp.in/free/invoicing-software/e-invoicing'),
            ('Vyapar offline billing', 'https://vyaparapp.in/use-cases/offline-billing'),
        ],
    },

    # ── myBillBook ─────────────────────────────────────────────────
    {
        'slug': 'mybillbook',
        'name': 'myBillBook',
        'title': 'myBillBook Alternative: Free GST Billing, No Subscription | BillZap',
        'desc': ('A free myBillBook alternative for Indian shops: unlimited GST '
                 'invoices, UPI QR on every bill, works offline, no account. '
                 'myBillBook plans start at ₹3,490/yr. Compared honestly.'),
        'keywords': ('mybillbook alternative, mybillbook free alternative, '
                     'mybillbook vs billzap, mybillbook price, free gst billing app'),
        'h1': 'Looking for a myBillBook alternative?',
        'lead': (
            'BillZap is a free alternative to myBillBook for shops that want '
            'GST invoices without a yearly bill. myBillBook’s plans started at '
            '₹3,490 a year when we checked; BillZap has no plans at all. '
            'myBillBook syncs across phones, iPhone and the web and lets your CA '
            'log in. BillZap stays on one Android phone and works without internet.'),
        'pick_us': [
            'You do not want to pay ₹3,490 or more every year for billing.',
            'Your shop has patchy signal and a bill must never wait for the network.',
            'You prefer no account and no copy of your books on a server.',
            'You want voice billing in an Indian language and a UPI QR on every unpaid bill.',
        ],
        'pick_them': [
            'You need the same books on an iPhone, the web or more than one device.',
            'You want your CA to log in to your books directly.',
            'You need e-way bills, e-invoicing or POS billing (on myBillBook’s top plan).',
            'You need more than one user or more than one business.',
        ],
        'rows': [
            ('Price', 'Plus ₹3,490 a year, Pro ₹3,990 a year, Pro Max from ₹570 a month billed annually, at the time of checking', US['price'], 'us'),
            ('Trying it first', 'Free trial, and a 7-day money-back guarantee', 'Nothing to trial. The free app is the whole app', 'us'),
            ('Platforms', 'Android, iOS and web; a desktop app on Pro and above', US['platforms'], 'them'),
            ('Users', '1 user plus 1 CA on every plan; 3 users on Pro Max', US['users'], 'them'),
            ('Businesses', '2 businesses on Pro Max', 'One business', 'them'),
            ('E-way bills and e-invoicing', 'On Pro Max', US['einv'], 'them'),
            ('Tally export', 'On request, on Pro Max', 'CSV and PDF reports to hand to your CA', 'them'),
            ('Account needed', 'Yes. You sign in, which is how the same books open on every device and for your CA', US['account'], 'us'),
            ('Works with no internet', 'Not stated on the pages we checked', US['offline'], None),
            ('Voice billing', 'Not a listed feature on the pages we checked', US['voice'], 'us'),
        ],
        'why': [
            ('A yearly bill for something used for one job',
             'For a shop that uses myBillBook to make invoices and send them on '
             'WhatsApp, ₹3,490 to ₹3,990 a year is paying for multi-device '
             'sync and a desktop app that never get opened. That money is a week '
             'of stock for many kirana stores.'),
            ('The good features are on the top plan',
             'E-way bills, e-invoicing, POS mode, extra users and a second business '
             'are on Pro Max, priced monthly and billed for the year. Shops that '
             'need one of those features end up paying for all of them.'),
            ('A login between you and your bills',
             'A cloud app keeps your books on its servers, which is what makes '
             'sync and CA access work. Some owners would simply rather their '
             'customer list and sales stayed on their own phone.'),
        ],
        'diff': [
            ('Free means free', 'No trial clock, no plan names, no money-back window to remember. Unlimited invoices and every report from the first day, for as long as you use it.'),
            ('Built for a weak signal', 'BillZap writes every bill to the phone’s own storage. Nothing waits to sync, so the bill is done the moment you press save.'),
            ('Your CA still gets what they need', 'The month-wise GST summary is laid out for GSTR-1, with taxable value, CGST, SGST and IGST, and exports as PDF or CSV to send on WhatsApp or email.'),
            ('Twelve languages, spoken or tapped', 'The whole app, and the voice billing, works in English, Hindi, Tamil, Telugu, Kannada, Malayalam, Marathi, Gujarati, Bengali, Punjabi, Odia and Urdu.'),
        ],
        'better': (
            'myBillBook is the better choice for a business that genuinely uses '
            'what it charges for: books on several devices, an iPhone or a laptop, '
            'a CA who logs in, two or three staff billing at once, or e-way bills '
            'and e-invoices from the same place. BillZap is one phone and one user, '
            'and it does not generate e-way bills or IRNs.'),
        'faq': [
            ('Is there a free alternative to myBillBook?',
             'Yes. BillZap is a free GST billing app with no paid tier and no invoice '
             'limit. myBillBook offers a free trial and then paid plans, which started '
             'at ₹3,490 a year when we checked in October 2026.'),
            ('Can my CA see my BillZap invoices like in myBillBook?',
             'Not by logging in, because BillZap has no server or accounts. You export '
             'the GST summary and other reports as PDF or CSV and send them to your CA.'),
            ('Does BillZap work on iPhone or the web?',
             'No. BillZap is an Android app. If you need iPhone or web access, '
             'myBillBook supports both.'),
            ('Will I lose my data if my phone breaks?',
             'Only if you never took a backup. BillZap saves a backup file you keep '
             'wherever you like, and restores it on a new phone.'),
        ],
        'sources': [
            ('myBillBook pricing', 'https://mybillbook.in/pricing-plans'),
        ],
    },

    # ── Khatabook ──────────────────────────────────────────────────
    {
        'slug': 'khatabook',
        'name': 'Khatabook',
        'title': 'Khatabook Alternative for GST Invoices, Free and Offline | BillZap',
        'desc': ('Need proper GST tax invoices, not just a khata? BillZap is a free '
                 'Khatabook alternative with CGST/SGST/IGST, HSN codes, UPI QR and '
                 'a GSTR-1 summary. No account, works offline.'),
        'keywords': ('khatabook alternative, khatabook gst invoice, khatabook vs '
                     'billzap, app like khatabook, free gst billing app'),
        'h1': 'Looking for a Khatabook alternative?',
        'lead': (
            'Khatabook started as a digital bahi khata — a record of who owes you '
            'what — and is very good at that. BillZap starts from the other end: '
            'a GST tax invoice with the right tax split, HSN codes and a UPI QR, '
            'made in about thirty seconds without an account or internet. Many '
            'shops that outgrow the khata need the invoice.'),
        'pick_us': [
            'Your customers ask for a proper GST tax invoice, not a ledger entry.',
            'You want CGST + SGST or IGST worked out from the place of supply.',
            'You want a month-wise GST summary for GSTR-1 ready for your CA.',
            'You want a UPI QR on the bill so the customer pays before leaving.',
            'You would rather not sign in to anything.',
        ],
        'pick_them': [
            'What you mostly track is udhaar: who owes you, and reminders to pay.',
            'You want the same records on your phone and a desktop, synced.',
            'Staff and the owner both need to see the books from different devices.',
            'You manage several businesses from one account.',
        ],
        'rows': [
            ('What it is built around', 'A digital ledger (bahi khata) with payment reminders, plus invoices and inventory', 'The GST tax invoice, plus reports and payment collection', None),
            ('Price', 'Free apps; some features are premium', US['price'], None),
            ('Account needed', 'Yes. Several businesses can be run from one account', US['account'], 'us'),
            ('Devices', 'Desktop and mobile, with real-time sync', US['devices'], 'them'),
            ('Backup', 'Automatic, when connected to the internet', 'A backup file you save yourself', 'them'),
            ('Payment reminders', 'Auto reminders, a core feature', 'WhatsApp share with a UPI payment link on unpaid bills; ageing report', 'them'),
            ('GST tax split', 'Check Khatabook’s invoice options', 'CGST + SGST or IGST chosen from the place of supply and shown before saving', 'us'),
            ('GSTR-1 summary', 'Check Khatabook’s reports', US['gstr1'], 'us'),
            ('Voice billing', 'Not a listed feature on the pages we checked', US['voice'], 'us'),
        ],
        'why': [
            ('A khata is not a tax invoice',
             'A ledger entry tells you that Sharma ji owes ₹1,200. A GST tax '
             'invoice has to carry your GSTIN, the buyer’s GSTIN if registered, '
             'HSN codes, the taxable value and the CGST, SGST or IGST amounts. A '
             'shop that registers for GST, or starts selling to businesses, needs '
             'the second thing every day.'),
            ('The tax split is where mistakes happen',
             'Charging CGST + SGST to a buyer in another state, or IGST to one in '
             'your own, means cancelling and reissuing the bill. BillZap decides '
             'from the place of supply and shows you its choice before you save.'),
            ('Not everyone wants an account',
             'A synced ledger needs an account so the records can follow you to '
             'another device. If your books never leave the counter, that account '
             'is just one more login holding your customer list.'),
        ],
        'diff': [
            ('Invoice first', 'Pick a saved customer and items, or speak them, and the GST tax invoice is ready with both GSTINs, HSN or SAC codes and the right rates.'),
            ('Paid before they leave', 'An unpaid invoice prints a UPI QR for your own UPI ID. The customer scans and pays straight into your bank account.'),
            ('Ready for the accountant', 'The month-wise summary of taxable value, CGST, SGST and IGST exports as PDF or CSV, laid out the way a CA reads it for GSTR-1.'),
            ('Dues, without a ledger app', 'Outstanding invoices are sorted oldest first, with 0–30, 31–60, 61–90 and 90+ day buckets, so you can see who to chase.'),
        ],
        'better': (
            'Khatabook is the better choice if your business runs on credit and the '
            'main job is keeping track of who owes what and nudging them to pay. '
            'Its automatic reminders, synced desktop and mobile access and '
            'multi-business account are things BillZap does not try to do. Some '
            'shops use both: Khatabook for the khata, BillZap for the GST bills.'),
        'faq': [
            ('Is BillZap like Khatabook?',
             'Partly. Both are free apps for Indian shops, but Khatabook is built '
             'around a digital ledger and payment reminders, while BillZap is built '
             'around the GST tax invoice, with the CGST, SGST or IGST split, HSN '
             'codes, a UPI QR and a GSTR-1 summary.'),
            ('Can I use Khatabook and BillZap together?',
             'Yes. Some shops keep their udhaar ledger in Khatabook and make GST tax '
             'invoices in BillZap. The two apps do not share data.'),
            ('Does BillZap send payment reminders like Khatabook?',
             'Not automatically. You can share an unpaid invoice on WhatsApp with a '
             'UPI payment link attached, and the ageing report shows who has been '
             'outstanding longest.'),
            ('Does BillZap need an account like Khatabook?',
             'No. BillZap has no sign-up at all: no phone number, no OTP and no email.'),
        ],
        'sources': [
            ('Khatabook', 'https://khatabook.com/'),
        ],
    },

    # ── Zoho Invoice ───────────────────────────────────────────────
    {
        'slug': 'zoho-invoice',
        'name': 'Zoho Invoice',
        'title': 'Zoho Invoice Alternative for Shops: Offline GST Billing | BillZap',
        'desc': ('Zoho Invoice is free but online and account-based. BillZap is a '
                 'free GST billing app for the shop counter: works offline, no '
                 'sign-up, UPI QR on every bill, voice billing in 12 languages.'),
        'keywords': ('zoho invoice alternative, zoho invoice vs billzap, free '
                     'invoice app india, offline invoice app, gst billing app for shops'),
        'h1': 'Looking for a Zoho Invoice alternative?',
        'lead': (
            'Zoho Invoice and BillZap are both free, so this is not about price. '
            'Zoho Invoice is online invoicing for businesses that send bills by '
            'email and collect by card or gateway, on every platform, from a Zoho '
            'account. BillZap is for the shop counter: an Android app that bills '
            'with no internet and no sign-up, and puts a UPI QR on the bill.'),
        'pick_us': [
            'You bill customers standing at your counter, not clients by email.',
            'Your signal drops and the bill still has to go out.',
            'You want no Zoho account, or any account, behind your billing.',
            'You want customers to pay by scanning a UPI QR to your own UPI ID.',
            'Your staff would rather speak the bill than type it.',
        ],
        'pick_them': [
            'You work on a laptop or Mac as much as a phone.',
            'You collect online through Zoho Payments or another gateway.',
            'You need delivery challans with e-way bill details.',
            'You already use other Zoho apps and want them connected.',
        ],
        'rows': [
            ('Price', 'Free', US['price'], None),
            ('Platforms', 'Web, Android, iOS, Mac and Windows', US['platforms'], 'them'),
            ('Account needed', 'Yes, a Zoho account with email verification', US['account'], 'us'),
            ('Where your data lives', 'Zoho’s cloud', US['data'], None),
            ('GST rates', 'Predefined GST, intra-state and inter-state rates', US['gst'], None),
            ('E-way bills', 'E-way bill details on GST delivery challans', US['einv'], 'them'),
            ('Getting paid', 'Cards, net banking and UPI through Zoho Payments and other gateways', 'UPI QR straight to your own UPI ID; no gateway in the middle', None),
            ('Works with no internet', 'Online service', US['offline'], 'us'),
            ('Voice billing', 'Not a listed feature on the pages we checked', US['voice'], 'us'),
            ('Day close for the cash drawer', 'Not a listed feature', 'Cash in, UPI in, expenses out and the expected drawer total', 'us'),
        ],
        'why': [
            ('It is built for a desk, not a counter',
             'Zoho Invoice is excellent at what it is for: quotes, invoices emailed '
             'to clients, online payments, follow-ups. A counter sale is a different '
             'job — the customer is in front of you and wants the bill now.'),
            ('Online by design',
             'A cloud invoicing service needs the connection to reach your account. '
             'In a market where the signal comes and goes, the shop needs the bill '
             'to work whether or not the network does.'),
            ('Collecting through a gateway',
             'Gateway payments suit online invoices. At a counter, the customer '
             'already has a UPI app open; a QR for your own UPI ID on the bill is '
             'the shortest way to the money.'),
        ],
        'diff': [
            ('No sign-up', 'Install it, type the shop name, GSTIN and UPI ID, and make the first bill. No email to verify.'),
            ('Fully offline', 'Billing, reports and storage never touch a network. The one exception is voice billing, which uses Android’s own speech recognition.'),
            ('Counter tools', 'A day close that reconciles cash, UPI and expenses against the drawer, low-stock alerts, and printing to a WiFi or Bluetooth printer.'),
            ('In your language', 'Twelve Indian languages for the app and for voice billing, so staff can bill in the language they think in.'),
        ],
        'better': (
            'Zoho Invoice is the better choice for freelancers, agencies and '
            'service businesses that invoice clients by email, want to work across '
            'web, Mac, Windows and phone, collect through a payment gateway, or need '
            'delivery challans with e-way bill details. It is free and polished, and '
            'it connects to the rest of Zoho. BillZap does none of that; it is a '
            'counter app.'),
        'faq': [
            ('Is BillZap free like Zoho Invoice?',
             'Yes. Both are free. BillZap has no paid tier, no invoice limit and no '
             'account. Zoho Invoice is free and requires a Zoho account.'),
            ('Does BillZap work offline? Zoho Invoice does not seem to.',
             'Yes. BillZap stores everything on the phone and bills, reports and '
             'exports with no internet at all. Voice billing is the one feature that '
             'uses Android’s speech recognition, which may need a connection.'),
            ('Can customers pay a BillZap invoice online?',
             'They pay by scanning the UPI QR on the invoice with any UPI app, or '
             'through the UPI link in the WhatsApp message. There is no card gateway.'),
            ('Is there a desktop version of BillZap?',
             'No. BillZap runs on Android phones and tablets. Zoho Invoice is the '
             'better fit if you need web, Mac or Windows.'),
        ],
        'sources': [
            ('Zoho Invoice (India)', 'https://www.zoho.com/in/invoice/'),
        ],
    },

    # ── Swipe ──────────────────────────────────────────────────────
    {
        'slug': 'swipe',
        'name': 'Swipe',
        'title': 'Swipe Billing Alternative: Free, Offline, No Account | BillZap',
        'desc': ('Comparing Swipe billing app alternatives? BillZap is a simpler, '
                 'free GST billing app that works offline with no sign-up. Where '
                 'Swipe is better (e-invoicing, online store) is said plainly.'),
        'keywords': ('swipe alternative, swipe billing app alternative, swipe vs '
                     'billzap, getswipe alternative, free gst billing app'),
        'h1': 'Looking for a Swipe alternative?',
        'lead': (
            'Swipe is a broad business app: GST billing, quotations, purchase '
            'orders, POS and inventory, plus e-invoicing, e-way bills, an online store and integrations with Shopify and Tally, on '
            'phone, web and Windows. BillZap is narrower on purpose. It makes the '
            'GST bill, collects by UPI QR and works with no internet or account, '
            'and every part of it is free.'),
        'pick_us': [
            'You want billing only, without an online store or integrations you will not use.',
            'You want everything free, with no plan to outgrow.',
            'Your counter loses signal and you cannot wait for it.',
            'You want no account and your books on your own phone.',
            'You want to speak the bill in an Indian language.',
        ],
        'pick_them': [
            'You need e-invoicing or e-way bills.',
            'You make quotations, purchase orders or POS bills as well as invoices.',
            'You sell online and want a store linked to your billing.',
            'You use Shopify or Tally and want the data to flow.',
            'You bill from iPhone, the web or a Windows PC as well.',
        ],
        'rows': [
            ('Price', 'A free plan, with paid tiers for more features; see Swipe’s pricing page for current prices', US['price'], None),
            ('Platforms', 'Android, iOS, web and Windows', US['platforms'], 'them'),
            ('E-invoicing and e-way bills', 'Supported', US['einv'], 'them'),
            ('Online store', 'Included', 'No', 'them'),
            ('Integrations', 'Shopify and Tally', 'CSV and PDF exports', 'them'),
            ('Account needed', 'Yes. You sign in, which is how the same books open on every platform', US['account'], 'us'),
            ('Works with no internet', 'Not stated on the pages we checked', US['offline'], None),
            ('Quotations, purchase orders, POS', 'Included', 'Invoices only', 'them'),
            ('Voice billing', 'Not a listed feature on the pages we checked', US['voice'], 'us'),
            ('UPI QR on the bill', 'Check Swipe’s current plan', US['upi'], None),
        ],
        'why': [
            ('More than a counter needs',
             'An online store, e-commerce integrations and multi-platform sync are '
             'real value for a business selling in several places. For a single shop '
             'billing walk-in customers, they are menus to scroll past.'),
            ('Paid tiers for the bigger features',
             'Swipe has a free plan, and paid tiers above it. Shops that only make '
             'bills want to know they will never be asked to upgrade.'),
            ('Cloud first',
             'Swipe keeps your books in an account so they sync across devices. '
             'BillZap keeps them on one phone, which is less flexible and needs no '
             'connection or login.'),
        ],
        'diff': [
            ('One job, done quickly', 'A bill from a saved customer and catalogue in about thirty seconds, or spoken in one of twelve languages.'),
            ('No upgrade path', 'Every feature is in the free app. There is no tier above it to be nudged towards.'),
            ('Offline from the first launch', 'Nothing about billing waits on a network or a server.'),
            ('Clear GST working', 'CGST + SGST or IGST chosen from the place of supply and shown before you save, with HSN codes saved against each item.'),
        ],
        'better': (
            'Swipe is the better choice for businesses that need e-invoices and '
            'e-way bills, sell through an online store or Shopify, push data into '
            'Tally, or bill from an iPhone, the web or Windows. BillZap does none of '
            'those. It is the better choice only when what you need is the GST bill '
            'itself, free and offline.'),
        'faq': [
            ('Is BillZap a free alternative to Swipe?',
             'Yes. BillZap is completely free with no paid tier. Swipe has a free plan '
             'and paid tiers; check Swipe’s pricing page for current prices.'),
            ('Does BillZap do e-invoicing like Swipe?',
             'No. BillZap makes GST tax invoices and a GSTR-1 summary but does not '
             'generate e-invoice IRNs or e-way bills.'),
            ('Does BillZap have an online store?',
             'No. BillZap is a billing app for the counter. It has no online store or '
             'e-commerce integrations.'),
            ('Does BillZap need internet like Swipe?',
             'No. BillZap works fully offline. Your data is stored on your phone, not '
             'in a cloud account.'),
        ],
        'sources': [
            ('Swipe', 'https://getswipe.in/'),
            ('Swipe pricing', 'https://getswipe.in/pricing'),
        ],
    },

    # ── TallyPrime ─────────────────────────────────────────────────
    {
        'slug': 'tally',
        'name': 'Tally',
        'full_name': 'TallyPrime',
        'title': 'Tally Alternative for Shop Billing on Your Phone, Free | BillZap',
        'desc': ('Tally is full accounting software from ₹22,500 + GST. For '
                 'counter billing on a phone, BillZap is a free Tally alternative: '
                 'GST invoices, UPI QR, GSTR-1 summary for your CA. Offline.'),
        'keywords': ('tally alternative, free tally alternative, tally for mobile, '
                     'tallyprime price, tally vs billzap, billing app instead of tally'),
        'h1': 'Looking for a Tally alternative for billing?',
        'lead': (
            'TallyPrime is accounting software: ledgers, vouchers, inventory, GST '
            'returns, used by most Indian accountants. It is not really a billing '
            'app for the counter. If you need Tally’s books, keep Tally. If you '
            'need GST bills on a phone, BillZap does that for free, offline, and '
            'gives your CA a GSTR-1 summary to work from.'),
        'pick_us': [
            'You need to make GST bills, not keep double-entry books.',
            'You want to bill from a phone at the counter, not a Windows PC.',
            'You do not want to pay ₹22,500 + GST for a licence.',
            'Your CA keeps your books and only needs your sales summary.',
        ],
        'pick_them': [
            'You keep your own full accounts: ledgers, vouchers, bank reconciliation.',
            'You file GST returns and generate e-invoices and e-way bills yourself.',
            'You run inventory across godowns, batches or multiple users.',
            'Your accountant works in Tally and wants you on it too.',
        ],
        'rows': [
            ('What it is', 'Full accounting, inventory and compliance software', 'A GST billing app for the counter', None),
            ('Price', 'Silver (one user) ₹22,500 + 18% GST one-time; Gold (unlimited users on a local network) ₹67,500 + GST; or rent Silver from ₹750 a month', US['price'], 'us'),
            ('Trying it first', '7-day free trial; a free educational version', 'The free app is the whole app', 'us'),
            ('Platforms', 'Desktop (Windows)', US['platforms'], None),
            ('Double-entry accounting', 'Yes, its core', US['accounts'], 'them'),
            ('GST returns, e-invoices and e-way bills', 'Yes', 'GSTR-1 summary for your CA; no returns, IRNs or e-way bills', 'them'),
            ('Multi-user', 'Gold: unlimited users on a local network', US['users'], 'them'),
            ('Learning curve', 'Made for accountants', 'Made for the person at the counter', 'us'),
            ('Voice billing', 'No', US['voice'], 'us'),
        ],
        'why': [
            ('Tally lives on a PC in the back office',
             'Many shop owners have Tally because their accountant does. But the '
             'bill is made at the counter, often on a phone, often by someone who '
             'has never been trained in Tally.'),
            ('A licence for one task',
             'A Silver licence costs ₹22,500 plus GST. Paying that to make sales '
             'bills, when the accounting is done by the CA anyway, is a lot.'),
            ('Shops want speed, not vouchers',
             'Tally asks you to think in vouchers and ledgers. A shop wants to pick '
             'the items, see the total, take the payment and send the PDF.'),
        ],
        'diff': [
            ('A bill in thirty seconds', 'Customer, items, the tax split, a UPI QR and a WhatsApp share, all from one screen on the phone.'),
            ('Something your CA can use', 'The month-wise GST summary splits taxable value into CGST, SGST and IGST and exports as CSV or PDF, so the accountant can enter it in Tally.'),
            ('Free, with nothing to renew', 'No licence, no renewal, no rental. Install it from Google Play.'),
            ('Works where the PC is not', 'At the counter, at a customer’s site, at a market stall, with or without signal.'),
        ],
        'better': (
            'Tally is the better choice, and often the only choice, for actual '
            'accounting: ledgers, vouchers, bank reconciliation, inventory across '
            'locations, GST returns, e-invoices and e-way bills, and anything your '
            'auditor needs. BillZap is not accounting software. The common setup is '
            'both: BillZap at the counter for the bills, Tally with the CA for the books.'),
        'faq': [
            ('Is BillZap a replacement for Tally?',
             'Not for accounting. BillZap makes GST bills and sales reports; it does '
             'not keep double-entry books or file returns. It replaces Tally only if '
             'the one thing you used Tally for was making bills.'),
            ('Can I export BillZap data to Tally?',
             'There is no direct Tally export. BillZap exports the GST summary and '
             'other reports as CSV and PDF, which your accountant can enter in Tally.'),
            ('How much does Tally cost compared with BillZap?',
             'According to Tally Solutions, TallyPrime Silver for one user is ₹22,500 '
             'plus 18% GST as a one-time licence, Gold is ₹67,500 plus GST, and '
             'Silver can be rented from ₹750 a month. BillZap is free with no paid tier.'),
            ('Is there a free version of Tally?',
             'Tally offers a 7-day free trial and a free educational version for '
             'learning. BillZap is free for business use with no time limit.'),
        ],
        'sources': [
            ('TallyPrime cost of ownership (Tally Solutions)', 'https://tallysolutions.com/business-guides/tallyprime-total-cost-of-ownership-india/'),
            ('TallyPrime free trial', 'https://tallysolutions.com/business-software-7day-free-trial/'),
        ],
    },
]

# The two blog posts that go deeper on the comparisons.
READING = [
    ('/blog/best-gst-billing-apps', 'Best GST billing apps in India, compared'),
    ('/blog/vyapar-vs-mybillbook-vs-billzap', 'Vyapar vs myBillBook vs BillZap'),
]

# Hub table: one line per app.
HUB_ROWS = [
    ('BillZap', 'Free, no paid tier', 'GST bills at the counter, offline, no account', 'Android'),
    ('Vyapar', 'Free version; paid from ₹3,959/yr (offer price)', 'Billing with inventory and accounting, on desktop too', 'Android, Windows'),
    ('myBillBook', 'Free trial; from ₹3,490/yr', 'Multi-device billing with CA access', 'Android, iOS, web'),
    ('Khatabook', 'Free; premium features', 'Udhaar ledger and payment reminders', 'Android, iOS, desktop'),
    ('Zoho Invoice', 'Free', 'Online invoices and gateway payments', 'Web, Android, iOS, Mac, Windows'),
    ('Swipe', 'Free plan; paid tiers', 'E-invoicing, e-way bills and an online store', 'Android, iOS, web, Windows'),
    ('TallyPrime', '₹22,500 + GST one-time (Silver)', 'Full accounting and GST returns', 'Windows'),
]

HUB_TITLE = 'BillZap Alternatives Compared: Vyapar, myBillBook, Tally & More'
HUB_DESC = ('BillZap compared honestly with Vyapar, myBillBook, Khatabook, Zoho '
            'Invoice, Swipe and Tally: prices, offline use, platforms, and when '
            'each one is the better choice.')


def esc(s):
    return html.escape(s, quote=True)


def strip(s):
    return re.sub(r'<[^>]+>', '', s)


def _ul(items):
    return '\n'.join(f'<li>{{{{ico:circle-check}}}} <span>{esc(i)}</span></li>'
                     for i in items)


def _tick():
    return '<span class="tk">{{ico:check}}</span>'


def _table(a):
    name = esc(a.get('full_name', a['name']))
    rows = []
    for label, them, us, win in a['rows']:
        tc = ' class="yes"' if win == 'them' else ''
        uc = 'yes col-us' if win == 'us' else 'col-us'
        rows.append(
            f'<tr><th scope="row">{esc(label)}</th>'
            f'<td{tc} data-label="{name}">{_tick() if win == "them" else ""}{esc(them)}</td>'
            f'<td class="{uc}" data-label="BillZap">{_tick() if win == "us" else ""}{esc(us)}</td></tr>')
    return f"""<div class="cmp-wrap rv">
  <table class="cmp cmp-stack">
    <caption>BillZap and {name}, checked {CHECKED_HUMAN}. A tick marks the stronger side; no tick means it depends on what you need.</caption>
    <thead><tr><th scope="col">What you are comparing</th><th scope="col">{name}</th><th scope="col" class="col-us">BillZap</th></tr></thead>
    <tbody>
{chr(10).join(rows)}
    </tbody>
  </table>
</div>"""


def _faq(items):
    return '\n'.join(
        f'<details><summary>{esc(q)} {{{{ico:chevron-down}}}}</summary>'
        f'<div class="a"><p>{esc(ans)}</p></div></details>'
        for q, ans in items)


def _others(slug):
    cards = []
    for a in ALTS:
        if a['slug'] == slug:
            continue
        cards.append(
            f'<a class="alt-link" href="/alternatives/{a["slug"]}/">'
            f'<span>BillZap vs</span> <b>{esc(a.get("full_name", a["name"]))}</b>'
            f' {{{{ico:arrow-right}}}}</a>')
    return '\n'.join(cards)


def _reading():
    return '\n'.join(f'<li>{{{{ico:book-open}}}} <span><a href="{u}">{esc(t)}</a></span></li>'
                     for u, t in READING)


CTA = """<section class="sec" id="download">
  <div class="wrap">
    <div class="cta rv rv-s">
      <p class="eyebrow">Free download</p>
      <h2>Try it on your next bill</h2>
      <p class="lead">Free, with no account, no card and no trial running out. It keeps working when the network does not.</p>
      <div class="cta-btns">
        <a class="btn btn-primary btn-lg" data-store href="{{play}}" rel="noopener">Get it on Google Play <span class="chip">{{ico:arrow-right}}</span></a>
        <a class="btn btn-ghost btn-lg" href="/#features">See every feature</a>
      </div>
      <p class="cta-fine">Android 7.0 and above · about 32 MB · works offline from the first launch</p>
    </div>
  </div>
</section>"""


def page_body(a):
    name = esc(a['name'])
    full = esc(a.get('full_name', a['name']))
    why = '\n'.join(f'<h3>{esc(h)}</h3>\n<p>{esc(p)}</p>' for h, p in a['why'])
    diff = '\n'.join(
        f'<article class="card rv"><h3>{esc(h)}</h3><p>{esc(p)}</p></article>'
        for h, p in a['diff'])
    sources = ', '.join(
        f'<a href="{esc(u)}" rel="noopener nofollow" target="_blank">{esc(t)}</a>'
        for t, u in a['sources'])
    return f"""<main id="main">
<section class="legal alt-top">
  <div class="wrap">
    <nav class="crumbs" aria-label="Breadcrumb"><ol>
      <li><a href="/">BillZap</a></li>
      <li><a href="/alternatives/">Alternatives</a></li>
      <li aria-current="page">{name}</li>
    </ol></nav>
    <div class="legal-head">
      <p class="eyebrow">{full} alternative</p>
      <h1>{esc(a['h1'])}</h1>
      <p class="lead">{esc(a['lead'])}</p>
      <div class="hero-cta alt-cta">
        <a class="btn btn-primary btn-lg" data-store href="{{{{play}}}}" rel="noopener">Get BillZap free <span class="chip">{{{{ico:arrow-right}}}}</span></a>
        <a class="btn btn-ghost btn-lg" href="#side-by-side">See the comparison</a>
      </div>
      <p class="legal-meta">
        <span>{{{{ico:calendar}}}} Checked {CHECKED_HUMAN}</span>
        <span>{{{{ico:badge-check}}}} {full} facts from {full}’s own site</span>
      </p>
    </div>

    <h2 class="alt-h">The short answer</h2>
    <div class="grid g2 alt-pick">
      <article class="card rv pick-us">
        <div class="card-ico">{{{{ico:zap}}}}</div>
        <h3>Choose BillZap if</h3>
        <ul class="ticks">
{_ul(a['pick_us'])}
        </ul>
      </article>
      <article class="card rv pick-them" style="--d:80ms">
        <div class="card-ico">{{{{ico:store}}}}</div>
        <h3>Stay with {full} if</h3>
        <ul class="ticks">
{_ul(a['pick_them'])}
        </ul>
      </article>
    </div>

    <h2 class="alt-h" id="side-by-side">BillZap vs {full}, side by side</h2>
{_table(a)}
    <p class="alt-src">Sources for {full}: {sources}. Prices change and offers end; check the source before you decide. Something out of date? Tell us at the GitHub link in the footer and we will fix it.</p>

    <div class="prose alt-prose">
      <h2>Why shops look for a {name} alternative</h2>
{why}
    </div>

    <h2 class="alt-h">What BillZap does differently</h2>
    <div class="grid g2 alt-diff">
{diff}
    </div>

    <div class="prose alt-prose">
      <h2>Where {full} is the better choice</h2>
      <p>{esc(a['better'])}</p>

      <h2>How to switch from {name} to BillZap</h2>
      <ol class="steps">
        <li><b>Keep {name} for your past records.</b> <span>Finish the month in {name}, and keep it installed for the invoices and reports you have already made there.</span></li>
        <li><b>Set up your shop in BillZap.</b> <span>Install it from Google Play and enter the shop name, GSTIN, UPI ID and bank details. It takes about a minute, with no sign-up.</span></li>
        <li><b>Start a new invoice series.</b> <span>Set an invoice prefix such as BZ- in settings, so every number stays unique for the financial year and never clashes with your old ones.</span></li>
        <li><b>Add items and customers as they come.</b> <span>Save each item once with its HSN code and GST rate, and each regular customer with their GSTIN. After the first week most bills are a few taps.</span></li>
        <li><b>Hand your CA both sets.</b> <span>For the month you switch, send {name}’s report for the days before and BillZap’s GSTR-1 summary for the days after.</span></li>
      </ol>
    </div>

    <h2 class="alt-h">Questions about switching from {name}</h2>
    <div class="faq alt-faq rv">
{_faq(a['faq'])}
    </div>

    <h2 class="alt-h">Other comparisons</h2>
    <div class="alt-links">
{_others(a['slug'])}
      <a class="alt-link all" href="/alternatives/"><span>See</span> <b>all alternatives</b> {{{{ico:arrow-right}}}}</a>
    </div>
    <div class="prose alt-prose">
      <h2>Further reading</h2>
      <ul>
{_reading()}
      </ul>
    </div>
  </div>
</section>
{CTA}
</main>"""


def hub_body():
    rows = '\n'.join(
        (f'<tr class="us"><th scope="row">{esc(n)}</th><td class="yes col-us" data-label="Price">{esc(p)}</td><td class="col-us" data-label="Best for">{esc(b)}</td><td class="col-us" data-label="Runs on">{esc(pl)}</td></tr>'
         if n == 'BillZap' else
         f'<tr><th scope="row"><a href="/alternatives/{_slug_of(n)}/">{esc(n)}</a></th><td data-label="Price">{esc(p)}</td><td data-label="Best for">{esc(b)}</td><td data-label="Runs on">{esc(pl)}</td></tr>')
        for n, p, b, pl in HUB_ROWS)
    cards = '\n'.join(
        f"""<a class="card rv alt-card" href="/alternatives/{a['slug']}/">
  <span class="eyebrow">BillZap vs {esc(a.get('full_name', a['name']))}</span>
  <h3>{esc(a['h1'])}</h3>
  <p>{esc(re.split(r'(?<=[.?])\s', a['lead'], 1)[0])}</p>
  <span class="more">Read the comparison {{{{ico:arrow-right}}}}</span>
</a>""" for a in ALTS)
    return f"""<main id="main">
<section class="legal alt-top">
  <div class="wrap">
    <nav class="crumbs" aria-label="Breadcrumb"><ol>
      <li><a href="/">BillZap</a></li>
      <li aria-current="page">Alternatives</li>
    </ol></nav>
    <div class="legal-head">
      <p class="eyebrow">Alternatives</p>
      <h1>BillZap and the other GST billing apps, compared honestly</h1>
      <p class="lead">
        Every app on this page is good at something. BillZap is the free one
        for billing at the counter: no paid tier, no account and no internet
        needed. The others do more — desktop, sync, e-way bills, accounting —
        and most charge for it. Here is what each is for, so you can pick the
        right one.</p>
      <div class="hero-cta alt-cta">
        <a class="btn btn-primary btn-lg" data-store href="{{{{play}}}}" rel="noopener">Get BillZap free <span class="chip">{{{{ico:arrow-right}}}}</span></a>
      </div>
      <p class="legal-meta"><span>{{{{ico:calendar}}}} Checked {CHECKED_HUMAN}</span><span>{{{{ico:badge-check}}}} Prices from each app’s own site</span></p>
    </div>

    <h2 class="alt-h">At a glance</h2>
    <div class="cmp-wrap rv">
      <table class="cmp cmp-hub cmp-stack">
        <caption>Starting price, what each app is best for, and where it runs. Checked {CHECKED_HUMAN}.</caption>
        <thead><tr><th scope="col">App</th><th scope="col">Price</th><th scope="col">Best for</th><th scope="col">Runs on</th></tr></thead>
        <tbody>
{rows}
        </tbody>
      </table>
    </div>

    <h2 class="alt-h">One page per app</h2>
    <div class="grid g3">
{cards}
    </div>

    <div class="prose alt-prose">
      <h2>Further reading</h2>
      <ul>
{_reading()}
      </ul>
    </div>
  </div>
</section>
{CTA}
</main>"""


def _slug_of(name):
    for a in ALTS:
        if name in (a['name'], a.get('full_name')):
            return a['slug']
    raise SystemExit(f'no alternatives page for {name}')


def page_jsonld(a, site):
    url = f'{site}/alternatives/{a["slug"]}/'
    full = a.get('full_name', a['name'])
    graph = [
        {
            "@type": "WebPage",
            "@id": f"{url}#page",
            "url": url,
            "name": a['title'],
            "description": a['desc'],
            "inLanguage": "en-IN",
            "dateModified": CHECKED,
            "isPartOf": {"@id": f"{site}/#site"},
            "publisher": {"@id": f"{site}/#org"},
            "about": [
                {"@id": f"{site}/#app"},
                {"@type": "SoftwareApplication", "name": full,
                 "applicationCategory": "BusinessApplication",
                 "url": a['sources'][0][1]},
            ],
            "mainEntity": {"@id": f"{url}#faq"},
        },
        {
            "@type": "BreadcrumbList",
            "itemListElement": [
                {"@type": "ListItem", "position": 1, "name": "BillZap", "item": f"{site}/"},
                {"@type": "ListItem", "position": 2, "name": "Alternatives", "item": f"{site}/alternatives/"},
                {"@type": "ListItem", "position": 3, "name": f"{a['name']} alternative", "item": url},
            ],
        },
        {
            "@type": "FAQPage",
            "@id": f"{url}#faq",
            "mainEntity": [
                {"@type": "Question", "name": q,
                 "acceptedAnswer": {"@type": "Answer", "text": ans}}
                for q, ans in a['faq']
            ],
        },
    ]
    return json.dumps({"@context": "https://schema.org", "@graph": graph},
                      separators=(',', ':'), ensure_ascii=False)


def hub_jsonld(site):
    url = f'{site}/alternatives/'
    graph = [
        {
            "@type": "CollectionPage",
            "@id": f"{url}#page",
            "url": url,
            "name": HUB_TITLE,
            "description": HUB_DESC,
            "inLanguage": "en-IN",
            "dateModified": CHECKED,
            "isPartOf": {"@id": f"{site}/#site"},
            "publisher": {"@id": f"{site}/#org"},
            "about": {"@id": f"{site}/#app"},
            "mainEntity": {
                "@type": "ItemList",
                "itemListElement": [
                    {"@type": "ListItem", "position": i + 1,
                     "name": f"BillZap vs {a.get('full_name', a['name'])}",
                     "url": f"{site}/alternatives/{a['slug']}/"}
                    for i, a in enumerate(ALTS)
                ],
            },
        },
        {
            "@type": "BreadcrumbList",
            "itemListElement": [
                {"@type": "ListItem", "position": 1, "name": "BillZap", "item": f"{site}/"},
                {"@type": "ListItem", "position": 2, "name": "Alternatives", "item": url},
            ],
        },
    ]
    return json.dumps({"@context": "https://schema.org", "@graph": graph},
                      separators=(',', ':'), ensure_ascii=False)


def head(title, desc, url, keywords, site):
    return f"""<meta name="keywords" content="{esc(keywords)}">
<meta property="og:type" content="article">
<meta property="og:site_name" content="BillZap">
<meta property="og:title" content="{esc(title)}">
<meta property="og:description" content="{esc(desc)}">
<meta property="og:url" content="{url}">
<meta property="og:image" content="{site}/assets/og.png">
<meta property="og:locale" content="en_IN">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:image" content="{site}/assets/og.png">

<link rel="preload" as="font" type="font/woff2" href="/assets/fonts/plus-jakarta-sans-800-latin.woff2" crossorigin>
<link rel="preload" as="font" type="font/woff2" href="/assets/fonts/poppins-400-latin.woff2" crossorigin>"""


def build(*, document, render, css, site):
    """Every alternatives page as {output path: finished HTML}."""
    out = {}
    hub_url = f'{site}/alternatives/'
    out['alternatives/index.html'] = document(
        title=esc(HUB_TITLE), desc=esc(HUB_DESC), canonical=hub_url, css=css,
        ld=hub_jsonld(site), body=render(hub_body(), home='/'),
        head_extra=head(HUB_TITLE, HUB_DESC, hub_url,
                        'billzap alternatives, best gst billing app, vyapar alternative, '
                        'mybillbook alternative, khatabook alternative, tally alternative',
                        site),
        asset_prefix='/')
    for a in ALTS:
        url = f'{site}/alternatives/{a["slug"]}/'
        out[f'alternatives/{a["slug"]}/index.html'] = document(
            title=esc(a['title']), desc=esc(a['desc']), canonical=url, css=css,
            ld=page_jsonld(a, site), body=render(page_body(a), home='/'),
            head_extra=head(a['title'], a['desc'], url, a['keywords'], site),
            asset_prefix='/')
    return out
