"""The /features/ pages: one landing page per thing BillZap does.

Imported by build.py, which owns the document shell; this file holds
what the pages say and how they are laid out.

Every claim here is something the app does today, checked against the
app's own code (lib/), not against the marketing copy. Each page also
says what the feature does NOT do, because a shop that installs for a
feature it then cannot find is a one-star review, not a user.
"""
import html
import json

PLAY_NOTE = 'Free · No sign-up · Works offline · Android'


def esc(s):
    return html.escape(s, quote=True)


FEATURES = [
    # ── GST billing ───────────────────────────────────────────────
    {
        'slug': 'gst-billing',
        'nav': 'GST billing',
        'icon': 'receipt-text',
        'title': 'GST Billing App: Free GST Invoice Maker for Shops | BillZap',
        'desc': ('Make GST tax invoices on your phone in seconds. CGST, SGST or '
                 'IGST worked out, HSN on every line, numbered bills, PDF and '
                 'print. Free, offline, no sign-up.'),
        'keywords': ('gst billing app, gst invoice app, gst bill maker, free gst '
                     'billing software, tax invoice app, gst invoice generator'),
        'h1': 'GST bills in seconds,',
        'h1_hl': 'tax worked out for you.',
        'lede': ('Pick the customer, add items, and BillZap does the rest: the '
                 'right heading, CGST and SGST or IGST from the place of supply, '
                 'HSN codes, a running bill number and a clean PDF you can share '
                 'or print.'),
        'facts': ['CGST, SGST or IGST', 'HSN/SAC on every line', 'Numbered automatically'],
        'screen': '''<p class="s-k">Tax Invoice · SLS-1042</p>
<p class="s-t">Kumar Traders</p>
<div class="s-row"><span>Basmati Rice 5 kg × 2</span><b>₹1,298</b></div>
<div class="s-row"><span>Sunflower Oil 1 L × 3</span><b>₹465</b></div>
<div class="s-row"><span>Detergent 1 kg × 2</span><b>₹180</b></div>
<div class="s-line"></div>
<div class="s-row s-m"><span>CGST 2.5% + SGST 2.5%</span><b>₹88.15</b></div>
<div class="s-row s-m"><span>CGST 9% + SGST 9%</span><b>₹32.40</b></div>
<div class="s-row s-tot"><span>Total</span><b>₹2,064</b></div>
<div class="s-btns"><span>PDF</span><span>Print</span><span class="on">WhatsApp</span></div>''',
        'steps': [
            ('Set up your shop once', 'Business name, GSTIN, address and state. They print on every bill from then on.'),
            ('Add items in a tap', 'Pick from your product list with HSN and GST rate saved, or type a new line.'),
            ('Save, share, done', 'The bill is numbered, the tax is split correctly, and the PDF is ready for WhatsApp or print.'),
        ],
        'benefits': [
            ('receipt-text', 'The right heading', 'Tax Invoice when GST is charged, Bill of Supply for a registered shop billing without tax, and Bill for a shop with no GSTIN.'),
            ('calculator', 'Tax split for you', 'CGST + SGST inside your state, IGST across states, at 5%, 18% or any rate you set per product.'),
            ('file-check', 'HSN and SAC', 'Saved on each product and printed on every line, the way GSTR-1 needs it.'),
            ('list-checks', 'No gaps in numbering', 'Bills are numbered in sequence with your own prefix, so your series stays clean.'),
            ('printer', 'PDF and print', 'A professional PDF with your logo, and printing over Wi-Fi or Bluetooth through Android.'),
            ('wifi-off', 'Works offline', 'No internet, no server. The bill is made on your phone, in the shop.'),
        ],
        'compare': [
            ('Working out GST', 'Calculator and a rate chart', 'Done per line, per rate'),
            ('Bill numbers', 'Torn pages, missed numbers', 'Automatic sequence'),
            ('Customer copy', 'Carbon copy', 'PDF on WhatsApp in one tap'),
            ('Month-end', 'Adding up by hand', 'GST summary and GSTR-1 file ready'),
        ],
        'not_do': ['E-invoices (IRN) for businesses above ₹5 crore turnover', 'E-way bills', 'Filing your GST return (your CA files it using the GSTR-1 file)'],
        'faqs': [
            ('Is BillZap really free for GST billing?', 'Yes. There is no paid plan, no trial and no limit on bills.'),
            ('Does it work for both CGST/SGST and IGST?', 'Yes. BillZap compares your state with the customer\'s state and applies CGST + SGST or IGST accordingly.'),
            ('Can I bill without GST?', 'Yes. Turn GST off for a product or the whole shop and the bill heading changes to Bill of Supply or Bill automatically.'),
            ('Does it make e-invoices?', 'No. E-invoicing applies to businesses above ₹5 crore turnover; most shops are below it and use normal tax invoices.'),
            ('Can my CA get the data?', 'Yes. Export a GSTR-1 file and a GST summary as PDF or CSV from Reports.'),
        ],
        'related': ['non-gst-billing', 'reports-gstr1', 'upi-qr-billing'],
        'blogs': [('gst-invoice-format', 'GST invoice format: every field explained'), ('bill-format', 'Bill format for shops'), ('how-to-make-gst-bill-on-mobile', 'How to make a GST bill on mobile')],
    },
    # ── Non-GST billing ───────────────────────────────────────────
    {
        'slug': 'non-gst-billing',
        'nav': 'Non-GST bills',
        'icon': 'file-text',
        'title': 'Billing App Without GST: Free Bill Maker for Small Shops | BillZap',
        'desc': ('Not registered under GST? Make clean, numbered bills and cash '
                 'memos without GST. BillZap prints the right heading so you never '
                 'call a bill a tax invoice by mistake. Free, offline.'),
        'keywords': ('billing app without gst, non gst billing software, bill maker '
                     'app, cash memo app, bill of supply app, simple billing app'),
        'h1': 'Not under GST?',
        'h1_hl': 'Bill properly anyway.',
        'lede': ('Most small shops are below the GST limit, but customers still '
                 'want a proper bill. BillZap makes numbered bills without tax, '
                 'with your shop name, a UPI QR and the right heading, so you '
                 'never print "Tax Invoice" when you are not allowed to.'),
        'facts': ['No GSTIN needed', 'Right heading, automatically', 'UPI QR on every bill'],
        'screen': '''<p class="s-k">Bill · B-0217</p>
<p class="s-t">Priya Ramesh</p>
<div class="s-row"><span>Toor Dal 1 kg</span><b>₹168</b></div>
<div class="s-row"><span>Filter Coffee 500 g</span><b>₹285</b></div>
<div class="s-row"><span>Bath Soap × 4</span><b>₹180</b></div>
<div class="s-line"></div>
<div class="s-row s-tot"><span>Total</span><b>₹633</b></div>
<div class="s-qr"><i></i><span>Scan to pay ₹633</span></div>''',
        'steps': [
            ('Leave GSTIN empty', 'Set up your shop without a GSTIN. BillZap knows you are not registered.'),
            ('Bill as usual', 'Add items and prices. No tax is added, and the heading reads Bill.'),
            ('Get paid on the spot', 'The UPI QR carries the exact amount, so customers pay before they leave.'),
        ],
        'benefits': [
            ('badge-check', 'Correct heading', 'Bill for an unregistered shop; Bill of Supply for a registered shop billing without tax.'),
            ('list-checks', 'Numbered bills', 'Every bill gets the next number, unlike a bill book with torn pages.'),
            ('qr-code', 'UPI QR with the amount', 'The QR on the bill is for that exact amount.'),
            ('message-circle', 'Share on WhatsApp', 'Send the bill as a PDF with a pay link in the message.'),
            ('chart-column', 'Know your sales', 'Daily totals, pending dues and reports without a single register.'),
            ('trending-up', 'Ready when you grow', 'Add your GSTIN later and the same app starts making tax invoices.'),
        ],
        'compare': [
            ('Bill heading', '"Tax Invoice" pads by mistake', 'Bill or Bill of Supply, correctly'),
            ('Copies', 'Carbon pads', 'PDF, WhatsApp, print'),
            ('Payment', 'Customer asks for your UPI ID', 'QR with the amount on the bill'),
            ('Records', 'Loose bill books', 'Every bill searchable on your phone'),
        ],
        'not_do': ['Receipts or cash memos as a separate document type', 'Quotations or estimates'],
        'faqs': [
            ('Can I give a bill if I am not registered under GST?', 'Yes, and you should. It must not be called a tax invoice and must not charge GST. BillZap handles both automatically.'),
            ('What is a bill of supply?', 'The document a registered dealer issues when no tax is charged, for example a composition dealer or a shop selling exempt goods.'),
            ('Can I switch to GST billing later?', 'Yes. Add your GSTIN and set GST rates on your products; new bills become tax invoices.'),
            ('Is it free?', 'Yes, completely, with no limit on bills.'),
        ],
        'related': ['gst-billing', 'upi-qr-billing', 'whatsapp-invoice'],
        'blogs': [('cash-memo-format', 'Cash memo format'), ('gst-registration-limit', 'GST registration limit'), ('gst-composition-scheme', 'GST composition scheme')],
    },
    # ── UPI QR ────────────────────────────────────────────────────
    {
        'slug': 'upi-qr-billing',
        'nav': 'UPI QR on bills',
        'icon': 'qr-code',
        'title': 'UPI QR Code on Invoice: Get Paid Faster | BillZap',
        'desc': ('Every BillZap bill carries a UPI QR with the exact amount and bill '
                 'number. Customers scan with any UPI app and pay. Free invoice app '
                 'with UPI QR for Indian shops.'),
        'keywords': ('upi qr code on invoice, invoice with upi qr, bill with qr code, '
                     'dynamic upi qr, upi payment link invoice, qr code billing app'),
        'h1': 'A UPI QR on every bill,',
        'h1_hl': 'with the amount filled in.',
        'lede': ('Add your UPI ID once. From then on every unpaid rupee bill shows a '
                 'QR for its exact amount, with the bill number as the payment '
                 'note. No typing amounts, no wrong payments, no "send me your UPI '
                 'ID".'),
        'facts': ['Exact amount in the QR', 'Bill number as the note', 'Any UPI app'],
        'screen': '''<p class="s-k">Pay SLS-1042</p>
<div class="s-qrbig"><i></i></div>
<p class="s-t s-c">₹2,064.00</p>
<p class="s-k s-c">srilakshmi@upi</p>
<div class="s-apps"><span>GPay</span><span>PhonePe</span><span>Paytm</span><span>BHIM</span></div>
<div class="s-btns"><span class="on">Mark paid</span></div>''',
        'steps': [
            ('Add your UPI ID', 'In Settings, once. Your business or personal UPI ID both work.'),
            ('Make a bill', 'The QR appears on the bill and the PDF with the exact total.'),
            ('Customer scans and pays', 'Check your bank or UPI app, then tap Mark paid.'),
        ],
        'benefits': [
            ('qr-code', 'Amount pre-filled', 'The customer cannot type a wrong amount.'),
            ('receipt-text', 'Bill number as the note', 'Matching payments to bills in your bank statement is easy.'),
            ('message-circle', 'Pay link on WhatsApp', 'The WhatsApp message carries a tap-to-pay UPI link too.'),
            ('check-check', 'Mark paid', 'Once the money is in, mark the bill paid and the QR disappears from it.'),
            ('indian-rupee', 'Free for you', 'BillZap charges nothing; UPI to merchants is free for everyday payments.'),
            ('store', 'Counter and doorstep', 'Show the QR on your phone at the counter or send it with home deliveries.'),
        ],
        'compare': [
            ('Wrong amount', 'Customer types ₹206 instead of ₹2,064', 'Amount fixed in the QR'),
            ('Which bill was paid?', 'Guesswork in the bank statement', 'Bill number in the payment note'),
            ('Delivery payments', 'Call to share UPI ID', 'QR and pay link on the bill'),
        ],
        'not_do': ['Confirm payments automatically: check your bank or soundbox before marking a bill paid', 'Card payments'],
        'faqs': [
            ('Does BillZap confirm that the customer paid?', 'No. It is not connected to your bank. Check your UPI app or soundbox, then mark the bill paid.'),
            ('Which UPI apps can scan it?', 'Any UPI app: Google Pay, PhonePe, Paytm, BHIM or a bank app.'),
            ('Does it work for bills in other currencies?', 'No. UPI moves rupees only, so the QR appears only on rupee bills.'),
            ('Can I use a personal UPI ID?', 'Yes, though a business UPI ID or merchant QR is better for regular shop payments.'),
        ],
        'related': ['payment-reminders', 'whatsapp-invoice', 'gst-billing'],
        'blogs': [('upi-qr-code-for-shop', 'UPI QR code for your shop'), ('udhaar-management', 'How to recover udhaar')],
    },
    # ── WhatsApp invoices ─────────────────────────────────────────
    {
        'slug': 'whatsapp-invoice',
        'nav': 'WhatsApp bills',
        'icon': 'message-circle',
        'title': 'Send Invoice on WhatsApp: Free Bill Sharing App | BillZap',
        'desc': ('Send a GST bill on WhatsApp in one tap: a PDF plus a message with '
                 'the amount, due date and a UPI pay link. Free invoice app for '
                 'Indian shops, works offline.'),
        'keywords': ('send invoice on whatsapp, whatsapp bill app, invoice pdf '
                     'whatsapp, share bill on whatsapp, whatsapp payment reminder, '
                     'whatsapp billing app'),
        'h1': 'Bills on WhatsApp,',
        'h1_hl': 'with a pay link inside.',
        'lede': ('Your customers already live on WhatsApp. BillZap sends the bill '
                 'there: a clean PDF and a short message with the amount, the due '
                 'date and a UPI link they can tap to pay. Send it again later and '
                 'it works as a polite reminder.'),
        'facts': ['PDF + message', 'Amount, due date, pay link', 'Doubles as a reminder'],
        'screen': '''<p class="s-k">WhatsApp · Hotel Annapoorna</p>
<div class="s-chat"><b>Sri Lakshmi Stores</b><span>Hello Hotel Annapoorna, your bill SLS-1046 for ₹1,240 is ready.</span><span>Due by 30 Nov.</span><span class="s-link">Pay via UPI: upi://pay?...</span><span>Thank you!</span></div>
<div class="s-file">{{ico:file-text}}<span>BillZap_SLS-1046.pdf</span></div>''',
        'steps': [
            ('Make the bill', 'Add the customer with their phone number once.'),
            ('Tap WhatsApp', 'BillZap opens the chat with the message ready, in your language.'),
            ('Send the PDF', 'Share the PDF too, from the same screen.'),
        ],
        'benefits': [
            ('send', 'One tap', 'The chat opens with the customer\'s number and the message written.'),
            ('indian-rupee', 'UPI pay link', 'Customers tap the link and pay in their UPI app.'),
            ('calendar', 'Due date included', 'Clear terms, no awkward phone calls.'),
            ('bell-ring', 'Reminder ready', 'Resend the same message for unpaid bills.'),
            ('languages', 'In your language', 'The message follows the app language you use.'),
            ('sparkles', 'Festival greetings', 'Send greetings to your customers on festival days, one tap each.'),
        ],
        'compare': [
            ('Sending the bill', 'Photo of a paper bill', 'Proper PDF'),
            ('Asking for money', 'Awkward call', 'Message with amount and pay link'),
            ('Customer\'s copy', 'Lost by next week', 'Stays in their chat'),
        ],
        'not_do': ['Send WhatsApp messages automatically in bulk: you tap Send for each customer', 'WhatsApp Business API integration'],
        'faqs': [
            ('Do I need WhatsApp Business?', 'No. Normal WhatsApp or WhatsApp Business both work.'),
            ('What does the message say?', 'A greeting, the bill number and amount, the due date, a UPI pay link for rupee bills and a thank-you, in the app\'s language.'),
            ('Can I send reminders?', 'Yes. Open an unpaid bill and send it on WhatsApp again.'),
            ('Does it send messages automatically?', 'No. WhatsApp opens with the message ready and you tap Send.'),
        ],
        'related': ['payment-reminders', 'upi-qr-billing', 'gst-billing'],
        'blogs': [('whatsapp-business-for-shops', 'WhatsApp Business for shops'), ('udhaar-management', 'How to recover udhaar')],
    },
    # ── Offline billing ───────────────────────────────────────────
    {
        'slug': 'offline-billing',
        'nav': 'Offline billing',
        'icon': 'wifi-off',
        'title': 'Offline Billing App: GST Bills Without Internet | BillZap',
        'desc': ('Make GST bills with no internet at all. BillZap runs fully on your '
                 'phone: billing, stock, reports and storage. Free offline billing '
                 'app for shops with weak signal.'),
        'keywords': ('offline billing app, billing app without internet, offline gst '
                     'billing software, billing app no internet, offline invoice app'),
        'h1': 'No signal?',
        'h1_hl': 'Keep billing.',
        'lede': ('BillZap has no server. Bills, products, customers, stock and reports '
                 'all live on your phone, so the shop keeps running in a basement '
                 'market, a village, or the day the network goes down.'),
        'facts': ['No internet needed', 'No account or OTP', 'Your data stays on your phone'],
        'screen': '''<div class="s-sig">{{ico:signal-zero}}<span>No connection</span></div>
<p class="s-k">Today</p>
<p class="s-t">₹18,420</p>
<div class="s-row"><span>Bills today</span><b>37</b></div>
<div class="s-row"><span>Cash</span><b>₹6,980</b></div>
<div class="s-row"><span>UPI</span><b>₹11,440</b></div>
<div class="s-btns"><span class="on">+ New bill</span></div>''',
        'steps': [
            ('Install once', 'Download from Google Play. That is the last time you need data for billing.'),
            ('Bill without signal', 'Everything is saved on the phone instantly.'),
            ('Share when connected', 'WhatsApp and email go out whenever you have signal again.'),
        ],
        'benefits': [
            ('wifi-off', 'Zero downtime', 'No "server busy", no spinning wheel at the counter.'),
            ('lock', 'Private by design', 'No account, no cloud copy of your sales.'),
            ('zap', 'Fast on cheap phones', 'Nothing to load from the internet.'),
            ('hard-drive-download', 'Backup file', 'Make a PIN-protected backup and keep it where you like.'),
            ('printer', 'Print offline', 'Print to printers your phone supports.'),
            ('signal', 'Low data bills', 'Only sharing uses the internet, and only when you choose.'),
        ],
        'compare': [
            ('Network goes down', 'Queue at the counter', 'Billing carries on'),
            ('Where data lives', 'A company\'s server', 'Your phone'),
            ('Sign-up', 'Phone number and OTP', 'None'),
        ],
        'not_do': ['Sync between two phones: one phone holds the shop\'s data (move it with a backup file)', 'Cloud backup: you keep the backup file'],
        'faqs': [
            ('Does BillZap need internet at all?', 'Only to download it and to share on WhatsApp or email. Billing, stock and reports work offline.'),
            ('What if I lose my phone?', 'Restore from your latest backup file on the new phone. Keep backups in Drive or email.'),
            ('Can two phones share the same data?', 'Not live. BillZap is one phone per shop; you can move data with a backup.'),
            ('Is my data uploaded anywhere?', 'No. There is no server and no account.'),
        ],
        'related': ['app-lock-backup', 'gst-billing', 'stock-management'],
        'blogs': [('kirana-store-billing-app', 'Kirana store billing app guide'), ('best-gst-billing-apps', 'Best GST billing apps')],
    },
    # ── Voice billing ─────────────────────────────────────────────
    {
        'slug': 'voice-billing',
        'nav': 'Voice billing',
        'icon': 'mic',
        'title': 'Voice Billing App: Make Bills by Speaking | BillZap',
        'desc': ('Speak the bill and BillZap writes it: customer, items, quantities '
                 'and prices, in English, Hindi, Tamil and 9 more Indian languages. '
                 'Edit, then save. Free billing app.'),
        'keywords': ('voice billing app, billing by voice, speak to bill, hindi '
                     'voice billing, voice invoice, voice gst billing'),
        'h1': 'Too busy to type?',
        'h1_hl': 'Just say the bill.',
        'lede': ('Tap the mic and say it the way you would to a helper: "For Ravi, '
                 'two kilo sugar at 46, one oil at 155." BillZap picks out the '
                 'customer, items, quantities and prices, and you check them '
                 'before saving.'),
        'facts': ['12 languages', 'You check before saving', 'Edit anything'],
        'screen': '''<div class="s-mic"><i></i>{{ico:mic}}</div>
<p class="s-k s-c">I heard:</p>
<p class="s-q">"For Ravi, two kilo sugar at 46 and one oil at 155"</p>
<div class="s-row"><span>Sugar × 2</span><b>₹92</b></div>
<div class="s-row"><span>Oil × 1</span><b>₹155</b></div>
<div class="s-row s-tot"><span>Ravi · Total</span><b>₹247</b></div>''',
        'steps': [
            ('Tap the mic', 'Pick your speech language: English, Hindi, Tamil, Telugu and more.'),
            ('Say the bill', 'Customer first, then each item with quantity and price.'),
            ('Check and save', 'Fix anything it misheard, then save as a normal bill.'),
        ],
        'benefits': [
            ('mic', 'Hands-free start', 'Speak while you pack the order.'),
            ('languages', '12 speech languages', 'English, Hindi, Tamil, Telugu, Kannada, Malayalam, Marathi, Gujarati, Bengali, Punjabi, Odia and Urdu.'),
            ('check-check', 'You stay in control', 'Nothing is saved until you check it.'),
            ('receipt-text', 'Full GST bill', 'The result is a normal bill with tax, HSN and numbering.'),
            ('users', 'Helpers can use it', 'Easier for staff who type slowly.'),
            ('zap', 'Faster long bills', 'Read out a list instead of tapping item by item.'),
        ],
        'compare': [
            ('Long bill', 'Tap, search, type for each item', 'Say the list once'),
            ('Language', 'English keyboard', 'Your own language'),
        ],
        'not_do': ['Work on every phone: it uses your phone\'s speech recognition, which some phones lack or need internet for', 'Understand every accent perfectly: always check before saving'],
        'faqs': [
            ('Which languages does voice billing support?', 'English, Hindi, Tamil, Telugu, Kannada, Malayalam, Marathi, Gujarati, Bengali, Punjabi, Odia and Urdu.'),
            ('Does voice billing need internet?', 'It uses your phone\'s own speech recognition. Some phones can do this offline if the language pack is downloaded; others need internet.'),
            ('What should I say?', 'Start with "for" and the customer\'s name, then each item with quantity and price. Pause or say "and" between items.'),
            ('Can I edit what it heard?', 'Yes. Everything is editable before you save.'),
        ],
        'related': ['gst-billing', 'billing-in-indian-languages', 'offline-billing'],
        'blogs': [('how-to-make-gst-bill-on-mobile', 'How to make a GST bill on mobile'), ('kirana-store-billing-app', 'Kirana store billing app guide')],
    },
    # ── Stock management ──────────────────────────────────────────
    {
        'slug': 'stock-management',
        'nav': 'Stock & products',
        'icon': 'boxes',
        'title': 'Stock Management App for Shops: Low-Stock Alerts | BillZap',
        'desc': ('Keep a live stock count that drops as you bill, get low-stock '
                 'alerts, see your profit margin per product and import products '
                 'from a CSV. Free inventory app for small shops.'),
        'keywords': ('stock management app, inventory app for shop, low stock alert '
                     'app, product catalogue app, stock maintain app, inventory '
                     'management for small business'),
        'h1': 'Know what is on the shelf',
        'h1_hl': 'before it runs out.',
        'lede': ('Every product carries its price, GST rate, HSN, buying price and '
                 'stock. Each bill takes stock down, BillZap warns you when an item '
                 'runs low, and you can see the margin on every product.'),
        'facts': ['Stock drops as you bill', 'Low-stock alerts', 'Margin per product'],
        'screen': '''<p class="s-k">Products</p>
<div class="s-prod"><b>Basmati Rice 5 kg</b><span>₹649 · 42 left</span><em>13.7%</em></div>
<div class="s-prod low"><b>Toor Dal 1 kg</b><span>₹168 · 6 left</span><em>Low</em></div>
<div class="s-prod out"><b>Dark Chocolate</b><span>₹120 · 0 left</span><em>Out</em></div>
<div class="s-prod"><b>Sunflower Oil 1 L</b><span>₹155 · 60 left</span><em>14.8%</em></div>''',
        'steps': [
            ('Add products', 'Name, price, GST rate, HSN, buying price and opening stock. Or import from a CSV.'),
            ('Bill as usual', 'Stock goes down with every bill, automatically.'),
            ('Act on alerts', 'Low and out-of-stock items show up on your home screen.'),
        ],
        'benefits': [
            ('boxes', 'Live stock count', 'Always the current figure, not last month\'s register.'),
            ('bell', 'Low-stock alerts', 'Set a level per product; BillZap warns you before you run out.'),
            ('trending-up', 'Profit margin', 'Add a buying price and see the margin on each product.'),
            ('file-spreadsheet', 'CSV import', 'Bring products and customers from Excel or Google Sheets.'),
            ('file-check', 'HSN and GST saved', 'Set once, used on every bill.'),
            ('package', 'One product list', 'The same list for billing and stock.'),
        ],
        'compare': [
            ('Knowing stock', 'Walk to the shelf', 'Number on the screen'),
            ('Running out', 'Customer tells you', 'Alert before it happens'),
            ('Margin', 'Never really known', 'Shown per product'),
        ],
        'not_do': ['Barcode scanning', 'Purchase bills or supplier records (stock is adjusted by editing the product)', 'Size/colour variants, batches or expiry dates'],
        'faqs': [
            ('Does stock reduce automatically when I bill?', 'Yes. Each bill reduces the stock of the products on it.'),
            ('How do I add new stock?', 'Edit the product and update its stock figure. BillZap does not record purchase bills.'),
            ('Can I import my product list?', 'Yes, from a CSV file exported from Excel or Google Sheets.'),
            ('Does it scan barcodes?', 'No. Products are picked from the list by name.'),
        ],
        'related': ['reports-gstr1', 'gst-billing', 'expenses-day-close'],
        'blogs': [('stock-register-format', 'Stock register format'), ('profit-margin-formula', 'Profit margin formula'), ('inventory-management-techniques', 'Inventory management techniques')],
    },
    # ── Payment reminders ─────────────────────────────────────────
    {
        'slug': 'payment-reminders',
        'nav': 'Dues & reminders',
        'icon': 'bell-ring',
        'title': 'Payment Reminder App: Track Pending Bills & Dues | BillZap',
        'desc': ('See who owes you, oldest first. Mark bills paid or unpaid, see '
                 'overdue totals on the home screen and send a WhatsApp reminder '
                 'with a UPI link. Free app for shops.'),
        'keywords': ('payment reminder app, pending payment tracker, udhar tracking '
                     'app, overdue invoice reminder, customer dues app, payment '
                     'follow up whatsapp'),
        'h1': 'Know who owes you,',
        'h1_hl': 'and get it back.',
        'lede': ('Mark a bill unpaid and it joins Pending on your home screen; past '
                 'its due date, it turns Overdue. One tap sends the bill again on '
                 'WhatsApp with the amount and a UPI link, and Mark paid closes it '
                 'when the money arrives.'),
        'facts': ['Pending & overdue totals', 'WhatsApp reminder', 'Mark paid in a tap'],
        'screen': '''<p class="s-k">Pending</p>
<p class="s-t">₹68,508 <small>3 unpaid</small></p>
<div class="s-bar"><i style="width:60%"></i></div>
<div class="s-row s-red"><span>Overdue · Anand Super Market</span><b>₹40,877</b></div>
<div class="s-row"><span>Due 30 Nov · Kumar Traders</span><b>₹23,341</b></div>
<div class="s-row"><span>Due 5 Dec · Hotel Annapoorna</span><b>₹4,290</b></div>
<div class="s-btns"><span>Remind</span><span class="on">Mark paid</span></div>''',
        'steps': [
            ('Bill on credit', 'Leave the bill unpaid and set the due date.'),
            ('Watch the totals', 'Pending and Overdue show on your home screen, with the week ahead.'),
            ('Remind and close', 'Send it on WhatsApp again; mark it paid when the money comes.'),
        ],
        'benefits': [
            ('bell-ring', 'Overdue, flagged', 'Bills past their due date are shown in red.'),
            ('message-circle', 'Reminder with pay link', 'WhatsApp message with the amount, due date and UPI link.'),
            ('calendar-check', 'Week ahead', 'See which bills fall due this week.'),
            ('users', 'Top customers', 'See who buys the most from you this month.'),
            ('check-check', 'Mark paid or unpaid', 'Status changes in a tap and reports follow.'),
            ('chart-column', 'Status report', 'Paid, pending and overdue, with an ageing view, as PDF or CSV.'),
        ],
        'compare': [
            ('Remembering dues', 'Notebook and memory', 'Pending total on screen'),
            ('Asking for money', 'Awkward call', 'Polite message with a pay link'),
        ],
        'not_do': ['A running khata balance per customer with part payments', 'Automatic reminders: you send each one'],
        'faqs': [
            ('How do I mark a bill as unpaid?', 'Save it without marking it paid, or mark it unpaid later from the bill.'),
            ('Does BillZap send reminders automatically?', 'No. You open the bill and send it on WhatsApp; the message is ready for you.'),
            ('Can it record part payments?', 'No. A bill is paid or unpaid. For a running customer ledger, a khata app suits better.'),
            ('Where do I see overdue bills?', 'On the home screen under Pending, and in the invoice status report.'),
        ],
        'related': ['whatsapp-invoice', 'upi-qr-billing', 'reports-gstr1'],
        'blogs': [('udhaar-management', 'How to recover udhaar from customers'), ('upi-qr-code-for-shop', 'UPI QR code for shops')],
    },
    # ── Reports & GSTR-1 ──────────────────────────────────────────
    {
        'slug': 'reports-gstr1',
        'nav': 'Reports & GSTR-1',
        'icon': 'chart-column',
        'title': 'GST Reports & GSTR-1 Export App for Shops | BillZap',
        'desc': ('Sales, GST collected, profit & loss and invoice status, as PDF or '
                 'CSV, plus a GSTR-1 file for your CA. Free GST reports app for '
                 'small businesses, works offline.'),
        'keywords': ('gst report app, gstr-1 export, gst summary report, sales report '
                     'app, profit and loss app for shop, gst reports for ca'),
        'h1': 'Month-end in minutes,',
        'h1_hl': 'not a weekend.',
        'lede': ('BillZap turns your bills into the reports you and your accountant '
                 'need: revenue, a CGST/SGST/IGST summary, profit and loss with '
                 'expense categories, invoice status with ageing, and a GSTR-1 '
                 'file ready to hand over.'),
        'facts': ['GSTR-1 file', 'PDF and CSV', 'Any date range'],
        'screen': '''<p class="s-k">Reports · This month</p>
<div class="s-row"><span>Revenue</span><b>₹1,32,029</b></div>
<div class="s-row"><span>Expenses</span><b>₹34,300</b></div>
<div class="s-row s-tot"><span>Net profit</span><b>₹97,729</b></div>
<div class="s-bars"><i style="height:40%"></i><i style="height:62%"></i><i style="height:48%"></i><i style="height:75%"></i><i style="height:58%"></i><i style="height:92%"></i></div>
<div class="s-btns"><span>PDF</span><span>CSV</span><span class="on">GSTR-1</span></div>''',
        'steps': [
            ('Pick a period', 'This month, last month, this year, all time or custom dates.'),
            ('Pick a report', 'Revenue, GST summary, profit & loss or invoice status.'),
            ('Export and share', 'PDF or CSV for you, a GSTR-1 file for your CA.'),
        ],
        'benefits': [
            ('file-check', 'GSTR-1 file', 'A GSTR-1 file for the period, ready for your CA to check and upload.'),
            ('calculator', 'GST summary', 'CGST, SGST and IGST collected, period by period.'),
            ('trending-up', 'Profit & loss', 'Revenue minus expenses, with a breakdown by category.'),
            ('clock', 'Invoice status', 'Paid, pending and overdue, with ageing.'),
            ('users', 'Top customers', 'Earnings by customer and month-wise breakdown.'),
            ('file-spreadsheet', 'PDF or CSV', 'Readable reports or spreadsheet files.'),
        ],
        'compare': [
            ('GST for the month', 'Adding bills by hand', 'Summary in one tap'),
            ('Handing over to CA', 'Bag of bills', 'GSTR-1 file and CSV'),
            ('Profit', 'Guess', 'Profit & loss report'),
        ],
        'not_do': ['File GSTR-1 or GSTR-3B for you (your CA uploads and files)', 'Purchase or input tax credit reports', 'Double-entry accounting'],
        'faqs': [
            ('Can BillZap file my GST return?', 'No. It prepares the GSTR-1 file and summaries; you or your CA file on the GST portal.'),
            ('Which reports can I export?', 'Revenue, GST summary, profit & loss and invoice status, as PDF or CSV, plus a GSTR-1 file.'),
            ('Do reports include expenses?', 'Yes. Expenses you record appear in profit & loss.'),
            ('Can I export all my invoices?', 'Yes, as a CSV with the full tax breakdown, from Backup & Export.'),
        ],
        'related': ['gst-billing', 'expenses-day-close', 'stock-management'],
        'blogs': [('how-to-file-gstr-1', 'How to file GSTR-1'), ('gstr-3b', 'GSTR-3B guide'), ('gst-due-dates', 'GST due dates')],
    },
    # ── Expenses & day close ──────────────────────────────────────
    {
        'slug': 'expenses-day-close',
        'nav': 'Expenses & day close',
        'icon': 'wallet',
        'title': 'Expense Tracker & Day Close Report for Shops | BillZap',
        'desc': ('Record shop expenses by category and close each day with a summary '
                 'of collections by cash, UPI and bank, expenses and the net for the '
                 'day. Free app for small shops.'),
        'keywords': ('expense tracker for shop, day close report, daily sales report '
                     'app, cash drawer app, business expense app, daily collection '
                     'report'),
        'h1': 'Close the day',
        'h1_hl': 'knowing every rupee.',
        'lede': ('Record rent, salaries, electricity and small spends as they happen. '
                 'At night, Day close shows what came in by cash, UPI and bank, what '
                 'went out, and the net for the day, ready to share.'),
        'facts': ['Collections by mode', 'Expenses by category', 'Net for the day'],
        'screen': '''<p class="s-k">Day close · Today</p>
<div class="s-row"><span>Cash</span><b>₹6,980</b></div>
<div class="s-row"><span>UPI</span><b>₹11,440</b></div>
<div class="s-row"><span>Bank transfer</span><b>₹2,500</b></div>
<div class="s-row s-red"><span>Expenses today</span><b>− ₹850</b></div>
<div class="s-row s-tot"><span>Net for day</span><b>₹20,070</b></div>
<div class="s-btns"><span class="on">Share summary</span></div>''',
        'steps': [
            ('Add expenses', 'Title, amount, category and how you paid.'),
            ('Bill through the day', 'Payments are counted by mode as bills are marked paid.'),
            ('Close the day', 'Open Day close, check the net and share the summary.'),
        ],
        'benefits': [
            ('wallet', 'Business expenses', 'Rent, salary, utilities, transport and more, by category.'),
            ('banknote', 'Cash vs UPI', 'Know how much cash should be in the drawer.'),
            ('calendar', 'Any day', 'Look back at any date\'s close.'),
            ('share-2', 'Share the summary', 'Send the day\'s summary to a partner or yourself.'),
            ('trending-up', 'Feeds profit & loss', 'Expenses flow into your monthly report.'),
            ('piggy-bank', 'Personal spending apart', 'My Money keeps your own expenses separate from the shop\'s.'),
        ],
        'compare': [
            ('End of day', 'Counting and guessing', 'Collections by mode on screen'),
            ('Small expenses', 'Forgotten', 'Recorded and in profit & loss'),
        ],
        'not_do': ['A full double-entry cash book or ledger', 'Bank reconciliation'],
        'faqs': [
            ('What does Day close show?', 'Collections by payment mode (cash, UPI, bank and more), expenses for the day and the net.'),
            ('Are expenses included in reports?', 'Yes, in profit & loss with a breakdown by category.'),
            ('Can I see an earlier day?', 'Yes, pick any date.'),
            ('Is this the same as My Money?', 'No. Expenses here are the shop\'s; My Money tracks your personal spending against a budget.'),
        ],
        'related': ['reports-gstr1', 'payment-reminders', 'stock-management'],
        'blogs': [('cash-book-format', 'Cash book format'), ('profit-margin-formula', 'Profit margin formula')],
    },
    # ── Languages ─────────────────────────────────────────────────
    {
        'slug': 'billing-in-indian-languages',
        'nav': 'Indian languages',
        'icon': 'languages',
        'title': 'Billing App in Hindi, Tamil, Telugu & More | BillZap',
        'desc': ('Use a GST billing app in your own language: Hindi, Tamil, Telugu, '
                 'Kannada, Malayalam, Marathi, Gujarati, Bengali, Punjabi, Odia and '
                 'more. 125 languages, free.'),
        'keywords': ('billing app in hindi, billing app in tamil, gst billing app '
                     'hindi, billing software in telugu, regional language billing '
                     'app, hindi invoice app'),
        'h1': 'Billing in the language',
        'h1_hl': 'you think in.',
        'lede': ('BillZap\'s screens are available in 125 languages, including '
                 'Hindi, Tamil, Telugu, Kannada, Malayalam, Marathi, Gujarati, '
                 'Bengali, Punjabi, Odia, Urdu, Assamese and Konkani. Switch any '
                 'time; the bill your customer gets stays clear and readable.'),
        'facts': ['125 languages', 'Switch any time', 'Voice in 12 languages'],
        'screen': '''<p class="s-k">भाषा · Language</p>
<div class="s-langs"><span class="on">हिन्दी</span><span>தமிழ்</span><span>తెలుగు</span><span>ಕನ್ನಡ</span><span>മലയാളം</span><span>मराठी</span><span>ગુજરાતી</span><span>বাংলা</span><span>ਪੰਜਾਬੀ</span><span>ଓଡ଼ିଆ</span><span>اردو</span><span>English</span></div>
<p class="s-k">नया बिल</p>
<div class="s-btns"><span class="on">+ बिल बनाएं</span></div>''',
        'steps': [
            ('Pick your language', 'On first launch, or later in Settings.'),
            ('Use the app in it', 'Menus, buttons and messages switch instantly.'),
            ('Bill as usual', 'Your bills and GST work exactly the same.'),
        ],
        'benefits': [
            ('languages', '125 languages', 'Every major Indian language and many more.'),
            ('users', 'Easy for staff', 'Helpers can bill in the language they read best.'),
            ('mic', 'Voice billing', 'Speak bills in 12 languages including 11 Indian ones.'),
            ('message-circle', 'Messages in your language', 'WhatsApp bill messages follow the app language.'),
            ('file-text', 'Readable bills', 'PDFs keep a standard format your accountant can read.'),
            ('globe', 'Right-to-left too', 'Urdu and Arabic scripts read the right way.'),
        ],
        'compare': [
            ('Language', 'English only', 'Your language'),
            ('Training staff', 'Long explanations', 'They read it themselves'),
        ],
        'not_do': ['Translate item names you type: products show as you named them'],
        'faqs': [
            ('Is BillZap available in Hindi?', 'Yes, along with Tamil, Telugu, Kannada, Malayalam, Marathi, Gujarati, Bengali, Punjabi, Odia, Urdu and many more.'),
            ('How many languages does it support?', '125 languages for the app\'s screens; voice billing works in 12.'),
            ('Will my bill PDF be in Hindi?', 'Bills keep a standard format so customers, accountants and tax officers can all read them.'),
            ('Can I change the language later?', 'Yes, any time from Settings.'),
        ],
        'related': ['voice-billing', 'gst-billing', 'whatsapp-invoice'],
        'blogs': [('kirana-store-billing-app', 'Kirana store billing app guide'), ('how-to-start-a-kirana-store', 'How to start a kirana store')],
    },
    # ── App lock & backup ─────────────────────────────────────────
    {
        'slug': 'app-lock-backup',
        'nav': 'App lock & backup',
        'icon': 'shield-check',
        'title': 'App Lock & Backup for Your Billing Data | BillZap',
        'desc': ('Lock BillZap with a PIN or fingerprint and keep a PIN-protected '
                 'backup file of all your bills, customers and expenses. Your data '
                 'stays on your phone. Free and private.'),
        'keywords': ('billing app with backup, app lock billing app, secure billing '
                     'app, billing data backup, restore billing data, private '
                     'invoice app'),
        'h1': 'Your books are yours.',
        'h1_hl': 'Locked and backed up.',
        'lede': ('BillZap keeps everything on your phone, never on a server. Lock it '
                 'with a PIN or your fingerprint, and save a PIN-protected backup '
                 'file of every bill, customer and expense to keep wherever you '
                 'trust.'),
        'facts': ['PIN or fingerprint', 'PIN-protected backup', 'No server, no account'],
        'screen': '''<div class="s-lock">{{ico:fingerprint}}</div>
<p class="s-t s-c">BillZap is locked</p>
<p class="s-k s-c">Touch the sensor or enter your PIN</p>
<div class="s-pin"><i></i><i></i><i></i><i></i></div>
<div class="s-row"><span>Last backup</span><b>Today, 9:42 pm</b></div>''',
        'steps': [
            ('Turn on app lock', 'Set a 4-digit PIN and allow your fingerprint.'),
            ('Back up', 'Create a backup file protected by its own PIN.'),
            ('Keep it safe', 'Save it to Drive, email or WhatsApp. Restore it on any phone.'),
        ],
        'benefits': [
            ('fingerprint', 'Fingerprint unlock', 'Fast for you, closed to anyone else holding your phone.'),
            ('lock', 'PIN-protected backups', 'The backup file opens only with its PIN.'),
            ('rotate-ccw', 'Restore anywhere', 'Move to a new phone with your full history.'),
            ('key-round', 'Forgot PIN? Covered', 'Reset the app PIN using your latest backup file.'),
            ('shield-check', 'No server', 'Nothing to hack in the cloud, because nothing is there.'),
            ('file-spreadsheet', 'Export everything', 'All invoices as CSV whenever you want them.'),
        ],
        'compare': [
            ('Where your data is', 'A company\'s cloud', 'Your phone and your backup'),
            ('Phone lost', 'Hope', 'Restore from backup'),
        ],
        'not_do': ['Automatic cloud backup: you make the backup and choose where to keep it'],
        'faqs': [
            ('Where is my data stored?', 'Only on your phone, plus any backup files you make.'),
            ('What if I forget the app PIN?', 'Use Forgot PIN on the lock screen and choose your latest backup file to reset it.'),
            ('How do I move to a new phone?', 'Create a backup on the old phone, copy the file, install BillZap on the new one and restore.'),
            ('Is the backup file encrypted?', 'It is protected by a PIN you choose when creating it.'),
        ],
        'related': ['offline-billing', 'reports-gstr1', 'gst-billing'],
        'blogs': [('best-gst-billing-apps', 'Best GST billing apps')],
    },
]

BY_SLUG = {f['slug']: f for f in FEATURES}

HUB_TITLE = 'BillZap Features: Everything the Free GST Billing App Does'
HUB_DESC = ('GST and non-GST bills, UPI QR, WhatsApp sharing, offline billing, '
            'voice billing, stock alerts, payment reminders, GST reports and '
            'GSTR-1, 125 languages. All free.')


def _rv(i):
    return f' style="--d:{min(i, 6) * 70}ms"'


def phone(f):
    return f'''<div class="ft-phone" aria-hidden="true"><div class="ft-screen">{f["screen"]}</div></div>'''


def page_body(f):
    steps = '\n'.join(
        f'<li class="rv"{_rv(i)}><span class="ft-n">{i + 1}</span><b>{esc(t)}</b><p>{esc(d)}</p></li>'
        for i, (t, d) in enumerate(f['steps']))
    bens = '\n'.join(
        f'<div class="ft-ben rv"{_rv(i)}><span class="ft-bi">{{{{ico:{ic}}}}}</span><b>{esc(t)}</b><p>{esc(d)}</p></div>'
        for i, (ic, t, d) in enumerate(f['benefits']))
    rows = '\n'.join(
        f'<tr><th scope="row">{esc(a)}</th><td>{esc(b)}</td><td>{esc(c)}</td></tr>'
        for a, b, c in f['compare'])
    nots = '\n'.join(f'<li>{{{{ico:x}}}}<span>{esc(n)}</span></li>' for n in f['not_do'])
    faqs = '\n'.join(
        f'<details class="rv"><summary>{esc(q)} {{{{ico:chevron-down}}}}</summary><p>{esc(a)}</p></details>'
        for q, a in f['faqs'])
    rel = '\n'.join(
        f'<a class="ft-rc rv" href="/features/{r}/"><span class="ft-bi">{{{{ico:{BY_SLUG[r]["icon"]}}}}}</span><b>{esc(BY_SLUG[r]["nav"])}</b><span>{esc(CARD[r])}</span></a>'
        for r in f['related'])
    blogs = '\n'.join(
        f'<li><a href="/blog/{s}">{esc(t)} {{{{ico:arrow-right}}}}</a></li>' for s, t in f['blogs'])
    facts = '\n'.join(f'<li>{{{{ico:check}}}} {esc(x)}</li>' for x in f['facts'])
    return f'''<main id="main" class="ft">
<section class="ft-hero">
  <div class="ft-orbs" aria-hidden="true"><i></i><i></i><i></i></div>
  <div class="wrap ft-hero-in">
    <div class="ft-copy">
      <nav class="ft-crumb" aria-label="Breadcrumb"><a href="/">BillZap</a> <span>/</span> <a href="/features/">Features</a> <span>/</span> <b>{esc(f['nav'])}</b></nav>
      <p class="ft-pill">{{{{ico:{f['icon']}}}}} {esc(f['nav'])}</p>
      <h1>{esc(f['h1'])} <span>{esc(f['h1_hl'])}</span></h1>
      <p class="ft-lede">{esc(f['lede'])}</p>
      <div class="ft-cta">
        <a class="btn btn-primary btn-lg btn-gp" data-store href="{{{{play}}}}" rel="noopener">{{{{gp}}}} Download free <span class="chip">{{{{ico:arrow-right}}}}</span></a>
        <a class="btn btn-ghost btn-lg" href="/try">{{{{ico:monitor-smartphone}}}} Try in browser</a>
      </div>
      <ul class="ft-facts">{facts}</ul>
    </div>
    {phone(f)}
  </div>
</section>

<section class="ft-sec">
  <div class="wrap">
    <h2 class="rv">How it works</h2>
    <ol class="ft-steps">{steps}</ol>
  </div>
</section>

<section class="ft-sec ft-tint">
  <div class="wrap">
    <h2 class="rv">What you get</h2>
    <div class="ft-bens">{bens}</div>
  </div>
</section>

<section class="ft-sec">
  <div class="wrap ft-two">
    <div class="ft-cmp rv">
      <h2>Before and after</h2>
      <table><thead><tr><th scope="col"></th><th scope="col">Without BillZap</th><th scope="col">With BillZap</th></tr></thead><tbody>{rows}</tbody></table>
    </div>
    <div class="ft-not rv">
      <h2>What it does not do</h2>
      <p>We would rather you know now than after installing.</p>
      <ul>{nots}</ul>
    </div>
  </div>
</section>

<section class="ft-sec">
  <div class="wrap ft-faqwrap">
    <h2 class="rv">Questions</h2>
    <div class="ft-faq">{faqs}</div>
  </div>
</section>

<section class="ft-sec ft-tint">
  <div class="wrap">
    <h2 class="rv">More from BillZap</h2>
    <div class="ft-rel">{rel}</div>
    <div class="ft-reads rv"><b>Read next</b><ul>{blogs}</ul></div>
  </div>
</section>

<section class="ft-end">
  <div class="wrap">
    <div class="ft-endc rv">
      <h2>{esc(f['nav'])}, free on your phone.</h2>
      <p>BillZap is a complete GST billing app for Indian shops. No sign-up, no subscription, no internet needed.</p>
      <a class="btn btn-lg btn-gp ft-endb" data-store href="{{{{play}}}}" rel="noopener">{{{{gp}}}} Get BillZap free on Google Play <span class="chip">{{{{ico:arrow-right}}}}</span></a>
      <p class="ft-fine">{PLAY_NOTE}</p>
    </div>
  </div>
</section>
</main>'''


CARD = {
    'gst-billing': 'Tax invoices with CGST, SGST or IGST worked out, HSN on every line and numbered bills.',
    'non-gst-billing': 'Clean, numbered bills for shops below the GST limit, with the right heading.',
    'upi-qr-billing': 'A UPI QR on every bill with the exact amount and bill number filled in.',
    'whatsapp-invoice': 'Send the bill PDF on WhatsApp with the amount, due date and a pay link.',
    'offline-billing': 'Billing, stock and reports with no internet, no server and no account.',
    'voice-billing': 'Say the bill in 12 languages and check it before saving.',
    'stock-management': 'Stock that drops as you bill, low-stock alerts and margin per product.',
    'payment-reminders': 'Pending and overdue totals, WhatsApp reminders and mark paid in a tap.',
    'reports-gstr1': 'GST summary, profit and loss, invoice status and a GSTR-1 file for your CA.',
    'expenses-day-close': 'Shop expenses by category and a day close by cash, UPI and bank.',
    'billing-in-indian-languages': 'Use BillZap in Hindi, Tamil, Telugu and 122 more languages.',
    'app-lock-backup': 'PIN or fingerprint lock and a PIN-protected backup you keep.',
}


def hub_body():
    cards = '\n'.join(
        f'<a class="ft-hc rv" href="/features/{f["slug"]}/"{_rv(i % 6)}><span class="ft-bi">{{{{ico:{f["icon"]}}}}}</span><b>{esc(f["nav"])}</b><span>{esc(CARD[f["slug"]])}</span><em>Learn more {{{{ico:arrow-right}}}}</em></a>'
        for i, f in enumerate(FEATURES))
    cards += ('\n<a class="ft-hc rv" href="/my-money/"><span class="ft-bi">{{ico:wallet}}</span>'
              '<b>My Money</b><span>A personal expense tracker with a daily safe-to-spend number.</span>'
              '<em>Learn more {{ico:arrow-right}}</em></a>')
    return f'''<main id="main" class="ft">
<section class="ft-hero ft-hubhero">
  <div class="ft-orbs" aria-hidden="true"><i></i><i></i><i></i></div>
  <div class="wrap">
    <p class="ft-pill">{{{{ico:sparkles}}}} Features</p>
    <h1>Everything your shop needs to bill. <span>Free, on your phone.</span></h1>
    <p class="ft-lede">GST and non-GST bills, a UPI QR on every bill, WhatsApp sharing, stock alerts, payment reminders and the reports your CA asks for. No sign-up, no subscription, no internet needed.</p>
    <div class="ft-cta">
      <a class="btn btn-primary btn-lg btn-gp" data-store href="{{{{play}}}}" rel="noopener">{{{{gp}}}} Download free <span class="chip">{{{{ico:arrow-right}}}}</span></a>
      <a class="btn btn-ghost btn-lg" href="/try">{{{{ico:monitor-smartphone}}}} Try in browser</a>
    </div>
  </div>
</section>
<section class="ft-sec">
  <div class="wrap"><div class="ft-hub">{cards}</div></div>
</section>
<section class="ft-end">
  <div class="wrap">
    <div class="ft-endc rv">
      <h2>All of it, free.</h2>
      <p>No paid tier, no trial, no limit on bills.</p>
      <a class="btn btn-lg btn-gp ft-endb" data-store href="{{{{play}}}}" rel="noopener">{{{{gp}}}} Get BillZap free on Google Play <span class="chip">{{{{ico:arrow-right}}}}</span></a>
      <p class="ft-fine">{PLAY_NOTE}</p>
    </div>
  </div>
</section>
</main>'''


def page_jsonld(f, site):
    url = f'{site}/features/{f["slug"]}/'
    graph = [
        {"@type": "WebPage", "@id": f"{url}#page", "url": url, "name": f['title'],
         "description": f['desc'], "inLanguage": "en",
         "isPartOf": {"@id": f"{site}/#site"}, "about": {"@id": f"{site}/#app"}},
        {"@type": "FAQPage", "mainEntity": [
            {"@type": "Question", "name": q,
             "acceptedAnswer": {"@type": "Answer", "text": a}} for q, a in f['faqs']]},
        {"@type": "BreadcrumbList", "itemListElement": [
            {"@type": "ListItem", "position": 1, "name": "BillZap", "item": f"{site}/"},
            {"@type": "ListItem", "position": 2, "name": "Features", "item": f"{site}/features/"},
            {"@type": "ListItem", "position": 3, "name": f['nav'], "item": url}]},
    ]
    return json.dumps({"@context": "https://schema.org", "@graph": graph},
                      separators=(',', ':'), ensure_ascii=False)


def hub_jsonld(site):
    url = f'{site}/features/'
    graph = [
        {"@type": "CollectionPage", "@id": f"{url}#page", "url": url, "name": HUB_TITLE,
         "description": HUB_DESC, "inLanguage": "en",
         "isPartOf": {"@id": f"{site}/#site"}, "about": {"@id": f"{site}/#app"}},
        {"@type": "ItemList", "itemListElement": [
            {"@type": "ListItem", "position": i + 1, "name": f['nav'],
             "url": f"{site}/features/{f['slug']}/"} for i, f in enumerate(FEATURES)]},
        {"@type": "BreadcrumbList", "itemListElement": [
            {"@type": "ListItem", "position": 1, "name": "BillZap", "item": f"{site}/"},
            {"@type": "ListItem", "position": 2, "name": "Features", "item": url}]},
    ]
    return json.dumps({"@context": "https://schema.org", "@graph": graph},
                      separators=(',', ':'), ensure_ascii=False)


def head(title, desc, url, keywords, site):
    return f"""<meta name="keywords" content="{esc(keywords)}">
<meta property="og:type" content="website">
<meta property="og:site_name" content="BillZap">
<meta property="og:title" content="{esc(title)}">
<meta property="og:description" content="{esc(desc)}">
<meta property="og:url" content="{url}">
<meta property="og:image" content="{site}/assets/og-v2.png">
<meta property="og:locale" content="en_IN">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:image" content="{site}/assets/og-v2.png">

<link rel="preload" as="font" type="font/woff2" href="/assets/fonts/plus-jakarta-sans-800-latin.woff2" crossorigin>
<link rel="preload" as="font" type="font/woff2" href="/assets/fonts/poppins-400-latin.woff2" crossorigin>"""


def build(*, document, render, css, site):
    """Every feature page and the hub as {output path: finished HTML}."""
    out = {}
    hub = f'{site}/features/'
    out['features/index.html'] = document(
        title=esc(HUB_TITLE), desc=esc(HUB_DESC), canonical=hub, css=css,
        ld=hub_jsonld(site), body=render(hub_body(), home='/'),
        head_extra=head(HUB_TITLE, HUB_DESC, hub,
                        'billzap features, gst billing app features, free billing app, '
                        'billing app for shop, invoice app india', site),
        asset_prefix='/')
    for f in FEATURES:
        url = f'{site}/features/{f["slug"]}/'
        out[f'features/{f["slug"]}/index.html'] = document(
            title=esc(f['title']), desc=esc(f['desc']), canonical=url, css=css,
            ld=page_jsonld(f, site), body=render(page_body(f), home='/'),
            head_extra=head(f['title'], f['desc'], url, f['keywords'], site),
            asset_prefix='/')
    return out
