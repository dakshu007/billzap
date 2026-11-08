---
title: Nil GST Return: Who Can File It, How to File by SMS or Online, and the Late Fee
slug: nil-gst-return
meta_title: Nil GST Return: File GSTR-3B, GSTR-1, CMP-08 by SMS
meta_desc: How to file a nil GST return: who qualifies, nil GSTR-3B and GSTR-1 online or by SMS to 14409, nil CMP-08, the ₹500 late fee cap and non-filing risks.
focus_keyword: nil gst return
secondary_keywords: [how to file nil gstr 3b, nil return by sms, nil gstr 1, nil return late fee, who can file nil return, nil cmp-08]
tags: [GST guides, Returns]
excerpt: A plain guide to nil GST returns: the exact conditions for a nil GSTR-3B, GSTR-1 and CMP-08, the SMS format for 14409, the online steps, why a single purchase can stop a 3B from being nil, the late fee, and when cancelling your registration makes more sense.
publish_at: 2026-11-08T09:00:00+05:30
author: Dakshesh B
---

A shop shut for a month, a new registration that has not started selling, a seasonal business in its off months: all of them still have GST returns to file. With nothing to report they are **nil returns**, and they take about two minutes by SMS. Skip them and the late fee adds up, and after six months the department can cancel your registration.

Most guides stop at "send an SMS to 14409". This one also covers the conditions that decide whether your month is really nil (one purchase bill can stop it), rejected SMSes, the nil CMP-08, and when cancelling the registration makes more sense.

## Quick answer

- **A nil GSTR-3B** is for a period with **no sales, no reverse charge liability, no input tax credit to claim and no tax, interest or late fee due**. If any purchase shows up in your GSTR-2B, the portal will not accept a nil 3B.
- **A nil GSTR-1** only needs **no outward supplies**, no amendments, and no credit or debit notes for the period.
- **By SMS:** send `NIL 3B <GSTIN> <MMYYYY>` (or `NIL R1`, or `NIL C8` for CMP-08) to **14409** from the registered mobile number, then reply `CNF 3B <code>` within 30 minutes.
- **Online:** Returns Dashboard → GSTR-3B → Prepare Online → answer **Yes** to the nil question → file with EVC or DSC. For GSTR-1, tick **File Nil GSTR-1**.
- **Late fee:** ₹20 a day (₹10 CGST + ₹10 SGST), capped at **₹500 per return**. The portal's FAQ says there is **no late fee for CMP-08**.
- **Not filing:** a monthly filer who misses six months of returns, or a quarterly filer who misses two quarters, can have the registration cancelled.

## What counts as a nil return?

"Nil" means nothing to report, not "very little". Each return has its own test, so a period can be nil for one and not the other.

| Return | Can be filed nil when | Not nil if |
| --- | --- | --- |
| **GSTR-1** | No outward supplies in the period (including zero-rated, deemed exports and supplies under reverse charge) | Any sale at all, any amendment to an earlier invoice, any credit or debit note, any advance received for services |
| **GSTR-3B** | No outward supplies, no reverse charge liability, no ITC to claim, and no tax, interest or late fee due for this or an earlier period | Any sale (even exempt or nil-rated), any reverse charge purchase, anything in GSTR-2B, any ITC reversal, any pending late fee |
| **CMP-08** (composition) | No turnover and no reverse charge tax for the quarter | Any sale, or tax payable on a reverse charge purchase |

Three points trip people up.

**Exempt sales are still sales.** A shop that sold only fresh vegetables or loose rice (exempt from GST) in a month has outward supplies. Those go into Table 3.1(c) of GSTR-3B and Table 8 of GSTR-1. The return is not nil, even though no tax is payable.

**A purchase can make GSTR-3B non-nil.** The GST portal's manual says a nil GSTR-3B can be filed only if nothing is auto-populated from GSTR-2B. If a supplier uploaded an invoice in your GSTIN for that month, the 3B is not nil, even if you sold nothing. You file it online with zero sales and either claim or leave the credit. Your GSTR-1 for the same month can still be nil.

**Old dues block a nil 3B.** Interest or late fee owed from an earlier period makes the return non-nil until it is cleared.

### Who has to file at all?

Every normal and casual taxpayer files GSTR-1 and GSTR-3B for every period, active or not, until the registration is cancelled. Composition dealers file CMP-08 quarterly and GSTR-4 yearly. Our guide to [types of GST returns](https://billzap.app/blog/types-of-gst-returns) shows which forms apply to whom.

## How to file a nil GSTR-3B online

A nil return can be filed only from the 1st of the month after the period. October 2026's nil GSTR-3B can be filed from 1 November 2026.

1. Log in at **gst.gov.in**.
2. Go to **Services → Returns → Returns Dashboard**, pick the financial year and period, and click **Search**.
3. On the GSTR-3B tile, click **Prepare Online**.
4. The first question asks whether you want to file a nil return. Select **Yes** and click **Next**. The other questions grey out.
5. Click **Preview Draft GSTR-3B** if you want to see the summary. Every figure is zero and there is no payment table.
6. Tick the declaration, choose the authorised signatory, and click **File GSTR-3B with EVC** (an OTP to the registered mobile and email) or **with DSC**.
7. Download the filed return for your records.

If the nil option does not appear or will not switch to **Yes**, the portal has found something: data from GSTR-1 or IFF, an entry in GSTR-2B, a saved figure or an unpaid late fee. File the return normally; our [GSTR-3B guide](https://billzap.app/blog/gstr-3b) walks through the tables.

## How to file a nil GSTR-1 online

1. Returns Dashboard → choose the period → **Search**.
2. On the GSTR-1 tile, tick **File Nil GSTR-1**.
3. Click **File Statement**, tick the declaration and file with **EVC or DSC**.

If you had saved invoices in GSTR-1 earlier, delete them first or the nil option will not work. Quarterly (QRMP) filers file a nil GSTR-1 once for the quarter. The Invoice Furnishing Facility (IFF) in the first two months is optional, so if you have no business-to-business invoices in those months you simply do not file it; there is no "nil IFF". For a month with sales, see [how to file GSTR-1](https://billzap.app/blog/how-to-file-gstr-1).

[[cta: Know in ten seconds whether your month was nil | BillZap's reports show every bill, sales and GST collected for the month, so you are not guessing before you send that SMS. Free, no sign-up, works offline.]]

## How to file a nil return by SMS to 14409

SMS filing is the quickest way, and it works from a basic phone. It is a two-message exchange with the GST portal.

### Before you start

The GST portal lists these conditions for SMS filing:

- You are registered as a normal taxpayer, casual taxpayer, SEZ unit or SEZ developer (or as a composition taxpayer, for CMP-08).
- You send the SMS from the **mobile number of an authorised signatory registered on the portal**. If two signatories share the same number, SMS filing fails until each has a unique number.
- **All earlier GSTR-3B returns are filed** and there is no pending tax, interest or late fee.
- There is **no saved data** for that period in the online form.
- Your user ID is activated on the portal.

### The SMS formats

| What you want | Send to 14409 | Example |
| --- | --- | --- |
| Nil GSTR-3B, monthly | `NIL 3B <GSTIN> <MMYYYY>` | `NIL 3B 07AQDPP8277H8Z6 102026` |
| Nil GSTR-1, monthly | `NIL R1 <GSTIN> <MMYYYY>` | `NIL R1 07AQDPP8277H8Z6 102026` |
| Nil GSTR-1, quarterly | `NIL R1 <GSTIN> <last month of quarter>` | `NIL R1 07AQDPP8277H8Z6 122026` for October–December |
| Nil CMP-08 | `NIL C8 <GSTIN> <last month of quarter>` | `NIL C8 07AQDPP8277H8Z6 122026` for October–December |
| Confirm with the code | `CNF <3B, R1 or C8> <6-digit code>` | `CNF 3B 107543` |
| Help | `HELP 3B`, `HELP R1` or `HELP C8` | |

The GSTIN shown is the portal FAQ's sample; use your own.

### The steps

1. Send the `NIL` message to **14409**.
2. The portal checks the conditions and replies with a **6-digit verification code**. It is valid for **30 minutes** and works once.
3. Compose a **new** message (not a reply) to 14409: `CNF 3B` followed by the code.
4. You receive an **ARN** by SMS and email. The return now shows as **Filed** on the portal.

The text is not case-sensitive. Three wrong codes in a day block that GSTIN and mobile pair from SMS filing for 24 hours; you can still file online. A return filed by SMS cannot be revised. For a quarterly GSTR-3B, use the last month of the quarter as for GSTR-1; if the portal rejects it, file online.

### Why the SMS gets rejected

The reply SMS says why. The usual causes:

- **The return is late.** The pending late fee blocks the SMS route, so file online and pay the fee in cash.
- **An earlier return is pending.** File older periods first.
- **Saved data exists** for that period. Delete it online or finish the return there.
- **Wrong period format.** Six digits, month then year: `102026`, not `Oct2026`.
- **Wrong mobile number.** Use an authorised signatory's registered number.

## Nil CMP-08 and GSTR-4 for composition dealers

A composition dealer with no sales in a quarter files a **nil CMP-08** by the **18th of the month after the quarter**, either online or by SMS with the `C8` code above. The SMS uses the last month of the quarter: `062026` for April–June 2026, `122026` for October–December. CMP-08 for the previous quarter must already be filed.

The GST portal's CMP-08 FAQ states that **there is no late fee for delayed filing of CMP-08**. Interest at 18% a year still applies to any tax paid late, but a nil statement has no tax, so in practice a late nil CMP-08 costs nothing directly. It still counts as a missing return for the cancellation and e-way bill rules below, so file it.

The annual **GSTR-4** is due by 30 April and is filed online. Where it is filed late with no tax payable, the late fee is capped at **₹500** (₹250 CGST + ₹250 SGST) under the 2021 late fee notifications. More on the scheme in our [GST composition scheme](https://billzap.app/blog/gst-composition-scheme) guide.

## The nil return late fee

The late fee for a nil GSTR-3B or nil GSTR-1 is **₹20 a day**: ₹10 CGST and ₹10 SGST. Since June 2021 it has been capped at **₹500 per return** (₹250 + ₹250). It is paid in cash and cannot be paid from input tax credit.

The cap is reached after 25 days, because 25 × ₹20 = ₹500.

| Situation | Working | Late fee |
| --- | --- | --- |
| Nil GSTR-3B for October, filed 12 days late | 12 × ₹20 | ₹240 |
| Nil GSTR-1 and GSTR-3B for October, both 12 days late | 2 × ₹240 | ₹480 |
| Nil GSTR-3B filed 40 days late | 40 × ₹20 = ₹800, capped | ₹500 |
| Six months of nil GSTR-1 and GSTR-3B never filed, caught up later | 12 returns × ₹500 | ₹6,000 |

That last row is the common real case: a shop closed for renovation forgets that returns are still due. Two minutes of SMS a month would have cost nothing; six months later the bill is ₹6,000. Monthly due dates are in our [GST due dates](https://billzap.app/blog/gst-due-dates) calendar.

## What happens if you stop filing altogether

Late fees are the smaller problem. Continued non-filing has harder consequences:

- **Registration cancellation.** Under Section 29(2) and Rule 21, the proper officer can cancel the registration of a monthly filer who has not filed returns for a **continuous period of six months**, or a quarterly filer who has missed **two consecutive tax periods**. For a composition dealer, the trigger is not filing the annual return for **three months after its due date**.
- **E-way bills blocked.** If GSTR-3B is not filed for two or more consecutive periods (or CMP-08 for two consecutive quarters), the portal blocks e-way bill generation for that GSTIN.
- **Returns become impossible to file.** A return cannot be filed once three years have passed from its due date, and the portal began enforcing this in 2025. The gap then stays on your record.
- **Getting a cancelled registration back** means applying for revocation within the time allowed and filing every pending return with its late fee first.

## Should you cancel your registration instead?

Nil returns make sense for a pause: a seasonal business, a renovation, a new registration waiting for its first sale. If you have **stopped trading for good**, or registered voluntarily and never started, filing nil returns forever is the wrong answer.

| Your situation | Better choice |
| --- | --- |
| Shop shut for a month or two, reopening | Keep filing nil returns |
| Seasonal business, quiet for part of the year | Keep filing nil returns |
| Registered voluntarily, turnover well below the limit, no business buyers who need your GSTIN | Consider cancelling |
| Business closed, sold or merged | Cancel |

You apply online in form **REG-16**, file returns up to the cancellation date, pay back input tax credit on stock in hand, and file a final return, **GSTR-10**, within three months of the cancellation date or order, whichever is later. See how to [cancel GST registration](https://billzap.app/blog/cancel-gst-registration).

## Where BillZap fits

BillZap does not file GST returns, nil or otherwise, and it does not send filing reminders. Filing is on the GST portal or by SMS, as above.

It helps with the question before the SMS: **was this month really nil?** Every BillZap bill is numbered automatically, carries the right heading (Tax Invoice, Bill of Supply or Bill), and is counted in the reports, which show sales, GST collected and profit for the month. If the reports show bills, your GSTR-1 is not nil, and you can export them as PDF or CSV, or a GSTR-1 file, for your CA. It is free, needs no sign-up, works offline on Android and runs in Hindi and many other Indian languages. Try it in the browser at [billzap.app/try](https://billzap.app/try).

[[cta: The month you reopen, your first bill is ready | When sales start again, BillZap makes GST bills on your phone with HSN codes, CGST and SGST worked out and a UPI QR with the exact amount. Free, no sign-up, works offline.]]

## FAQ

### Who can file a nil GST return?

Any regular or casual taxpayer who, for that period, made no sales, had no reverse charge purchases, has no input tax credit to claim and owes no tax, interest or late fee. For GSTR-1 only the "no sales" part matters. Composition dealers with no turnover can file a nil CMP-08.

### How do I file a nil GSTR-3B by SMS?

From the registered mobile number of an authorised signatory, send `NIL 3B <GSTIN> <MMYYYY>` to 14409. You get a 6-digit code; send a new message `CNF 3B <code>` to 14409 within 30 minutes. An ARN comes back by SMS and email.

### Can I file a nil GSTR-3B if I bought goods but sold nothing?

Usually not. If the purchase appears in your GSTR-2B, the portal will not treat the 3B as nil. File it online with zero sales, and claim the credit if you are eligible. Your GSTR-1 for that month can still be nil.

### What is the late fee for a nil return?

₹20 a day (₹10 CGST + ₹10 SGST), capped at ₹500 per return. A late nil return usually cannot be filed by SMS, because the late fee is a pending liability; file it online and pay the fee in cash.

### Is there a late fee for a nil CMP-08?

According to the GST portal's FAQ, there is no late fee for a delayed CMP-08. Interest applies only to tax paid late, which a nil statement does not have. A missed CMP-08 still counts towards e-way bill blocking and cancellation.

## The bottom line

A nil return is the cheapest task in GST: no figures, no payment, one SMS and one code. The traps are in the conditions. One exempt sale makes GSTR-1 non-nil, one supplier invoice in GSTR-2B makes GSTR-3B non-nil, and a pending late fee pushes you off SMS. File every period from the 1st of the next month, and if the quiet has become permanent, cancel the registration instead of paying ₹500 a return to keep it alive.

*This guide is not tax advice. Portal conditions and late fees change; check the GST portal or your CA before you file.*
