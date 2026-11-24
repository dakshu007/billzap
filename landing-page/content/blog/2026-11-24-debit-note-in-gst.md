---
title: Debit Note in GST: When a Supplier Must Issue One, the Format, GSTR-1 Reporting and the Buyer's ITC Deadline
slug: debit-note-in-gst
meta_title: Debit Note in GST: Section 34(3), Format, ITC Time Limit
meta_desc: Debit note in GST explained: when Section 34(3) requires one, Rule 53 format, GSTR-1 and GSTR-3B reporting, the buyer's ITC deadline and a worked example.
focus_keyword: debit note in gst
secondary_keywords: [debit note under gst, section 34(3) gst, debit note format, debit note time limit, itc on debit note, debit note vs credit note, supplementary invoice gst]
tags: [GST guides, GST billing, Returns]
excerpt: A plain guide to debit notes under GST: when Section 34(3) says the supplier must issue one, the nine particulars Rule 53 requires, how to report it in GSTR-1 and GSTR-3B, why the buyer's ITC deadline runs from the debit note's date and not the invoice's, the buyer's "debit note" for purchase returns, and a worked example across two financial years.
publish_at: 2026-11-24T09:00:00+05:30
author: Dakshesh B
---

You billed a contractor for 50 tins of paint at ₹2,400 each. Then a price rise kicks in under your agreement, and you find 52 tins went out on the truck. The invoice is already in your GSTR-1, so GST gives you a separate document to add the difference: a **debit note**.

Most pages stop at a definition. This guide answers the questions people actually get stuck on: is there a deadline, which month's return does it go in, can the buyer still claim credit when the invoice is from last year, and what is the "debit note" a buyer sends when he returns goods?

## Quick answer

- A **debit note in GST** is a document the **supplier** issues under **Section 34(3) of the CGST Act** when the taxable value or tax on an invoice turns out to be **lower than it should be**: a price increase, short-billed tax, or more quantity supplied than billed.
- A **supplementary invoice** counts as a debit note under the Act.
- **Format:** no fixed form. **Rule 53(1A)** lists nine particulars, including the original invoice's number and date.
- **Reporting:** in **GSTR-1 Table 9B** for the month the debit note is issued (Section 34(4)), and the extra tax is paid through that month's **GSTR-3B**.
- **No issue deadline** in Section 34 for debit notes, unlike credit notes.
- **Buyer's ITC:** under **Section 16(4)**, the deadline runs from the **date of the debit note**, not the original invoice: 30 November after the end of the financial year in which the debit note is issued, or the annual return date if earlier (CBIC Circular 160/16/2021-GST).
- A buyer's own "debit note" for **goods returned** has no GST effect. The seller issues a **credit note** for returns.

## What Section 34(3) and 34(4) say

**Section 34(3)** applies where one or more tax invoices have been issued for a supply and the **taxable value or tax charged** in them is found to be **less than** the taxable value or tax payable on that supply. In that case the registered person who made the supply **shall** issue one or more debit notes to the recipient. "Shall" means this is not optional: if you under-billed, you must correct it.

**Section 34(4)** says the details of the debit note go into the return for the **month during which it was issued**, and the tax liability is adjusted (increased) accordingly.

The Explanation to Section 34 adds that "debit note" includes a **supplementary invoice**. So whether your software calls it a debit note or a supplementary invoice, the GST treatment is the same.

So only the **supplier** issues a GST debit note; it must relate to an **existing tax invoice**; and Section 34 sets **no time limit** for issuing it. Credit notes have the 30 November cut-off in Section 34(2); debit notes do not, because they increase the government's tax.

## When a supplier issues a debit note

| Situation | Debit note? | What it adds |
| --- | --- | --- |
| Price increased after the invoice under a price escalation clause or later agreement | Yes | Extra value and its tax |
| Rate per unit typed lower than agreed | Yes | The shortfall and its tax |
| Lower GST rate charged by mistake (say 5% instead of 18%) | Yes | The tax shortfall only |
| Tax left off an invoice for a taxable item | Yes | The full tax on that item |
| More quantity supplied under the same invoice than billed | Yes | The extra quantity and its tax |
| Extra goods sent later as a separate delivery | No, issue a **new tax invoice** | That is a fresh supply |
| Freight or packing agreed as part of the price but missed on the bill | Yes | The missed charge and its tax |
| Goods returned by the buyer | No, that needs a **credit note** | Reduces value and tax |
| Price reduced, or tax overcharged | No, that needs a **credit note** | Reduces value and tax |

A debit note does not fix the wrong tax head. If you charged CGST and SGST when IGST was due, or the reverse, that is handled under Section 77 and the refund rules; see [CGST, SGST and IGST](https://billzap.app/blog/cgst-sgst-igst-difference) and ask your CA.

## What a debit note must contain: Rule 53(1A)

There is no prescribed form, but **Rule 53(1A) of the CGST Rules** requires a debit note to carry:

1. Name, address and GSTIN of the supplier
2. Nature of the document (write "Debit Note")
3. A consecutive serial number, up to 16 characters, unique for the financial year
4. Date of issue
5. Name, address and GSTIN or UIN of the recipient, if registered
6. For an unregistered recipient: name and address, delivery address, and the name and code of the state
7. Serial number and date of the original tax invoice (or invoices)
8. Value of the taxable supply, the rate of tax and the amount of tax debited to the recipient
9. Signature or digital signature of the supplier or an authorised representative

Use a separate series, such as **DN/26-27/001**. If you are under e-invoicing, debit notes also need an IRN; see the [e-invoice limit](https://billzap.app/blog/e-invoice-limit) guide.

### Copyable debit note format

| Field | Entry |
| --- | --- |
| Document title | DEBIT NOTE |
| Supplier name, address | Your business name and full address |
| Supplier GSTIN | Your 15-character GSTIN |
| Debit note number | DN/26-27/003 |
| Debit note date | 10-04-2026 |
| Recipient name, address | Buyer's name and address |
| Recipient GSTIN | Buyer's GSTIN (if registered) |
| State and code (if unregistered) | e.g. Maharashtra, 27 |
| Against invoice number and date | INV/25-26/0918 dated 25-02-2026 |
| Reason | Price revision / short billing / tax short-charged / extra quantity |
| Place of supply | Same as the original invoice |

| Sr | Description | HSN | Qty | Rate (₹) | Taxable value (₹) | CGST % | CGST (₹) | SGST % | SGST (₹) | Total (₹) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Price revision on item supplied | xxxx | | | | | | | | |
| 2 | Quantity short-billed | xxxx | | | | | | | | |
| | **Total** | | | | | | | | | |

Add a signature; use one IGST column for inter-state supplies.

## Worked example: a debit note across two financial years

A paint distributor in Pune supplies a registered contractor in the same state. The paint is taxed at 18%.

**Original invoice INV/25-26/0918, dated 25 February 2026 (FY 2025-26)**

| Item | Working | Amount |
| --- | --- | --- |
| Taxable value | 50 tins × ₹2,400 | ₹1,20,000 |
| CGST 9% | | ₹10,800 |
| SGST 9% | | ₹10,800 |
| **Invoice total** | | **₹1,41,600** |

Two problems come to light in early April:

- The supply agreement passes on manufacturer price rises effective before delivery. The revised rate is **₹2,520** a tin, so the 50 billed tins are short by **₹120** each.
- The delivery challan and the contractor's goods receipt both show **52 tins**, but only 50 were billed. The 2 extra tins went on the same truck as part of the same supply.

**Debit note DN/26-27/003, dated 10 April 2026 (FY 2026-27)**

| Line | Working | Taxable value | CGST 9% | SGST 9% | Total |
| --- | --- | --- | --- | --- | --- |
| Price revision | 50 × ₹120 | ₹6,000.00 | ₹540.00 | ₹540.00 | ₹7,080.00 |
| Quantity short-billed | 2 × ₹2,520 | ₹5,040.00 | ₹453.60 | ₹453.60 | ₹5,947.20 |
| **Total** | | **₹11,040.00** | **₹993.60** | **₹993.60** | **₹13,027.20** |

**Check:** the supply should have been 52 × ₹2,520 = ₹1,31,040. Billed ₹1,20,000 + debit note ₹11,040 = **₹1,31,040**. Tax at 18% on ₹1,31,040 is ₹23,587.20, and ₹21,600 + ₹1,987.20 = **₹23,587.20**. He now owes **₹1,54,627.20** in all.

**Supplier side:** the debit note goes in the **April 2026 GSTR-1**, Table 9B, even though the invoice was in the February 2026 return. The extra **₹1,987.20** of tax is paid with the April 2026 GSTR-3B.

**Buyer side:** the contractor can claim the ₹1,987.20 as credit once it shows in his GSTR-2B. Because the debit note is dated in **FY 2026-27**, his deadline is **30 November 2027** (or the date he files his 2026-27 annual return, if earlier). If the deadline followed the February 2026 invoice, it would have been 30 November 2026. More on this below.

## Reporting a debit note in GSTR-1 and GSTR-3B

**GSTR-1**

- **Registered buyer:** Table **9B**, "Credit/Debit Notes (Registered)", with the buyer's GSTIN, note type "Debit", number, date and values.
- **Unregistered buyer:** Table 9B "Unregistered" covers exports and large inter-state B2C invoices; small consumer sales are usually netted in Table 7.
- **Corrections** to a debit note already reported go in Table **9C**. The debit note series goes in the document summary, Table **13**.
- **Month:** the month of the debit note's date, as Section 34(4) requires. Not the month of the original invoice.

Our step-by-step [GSTR-1 filing guide](https://billzap.app/blog/how-to-file-gstr-1) shows where each table sits on the portal.

**GSTR-3B**

The debit note's value and tax add to your outward taxable supplies in **Table 3.1(a)** for that month. On the portal this is auto-drafted from GSTR-1, so if the debit note is in GSTR-1, it flows into the draft. Pay the extra tax by the GSTR-3B due date. See our [GSTR-3B guide](https://billzap.app/blog/gstr-3b).

**Interest.** If the shortfall was a plain billing error known at the time of supply, an officer may argue the tax was due earlier. Fix errors as soon as you find them, and take your CA's view on older ones.

[[cta: Catch short billing before it needs a debit note | BillZap works out CGST, SGST or IGST from the rate on each product, numbers every bill automatically and shows the total before you share it. Free, works offline on Android.]]

## The buyer's ITC deadline: Section 16(4) follows the debit note date

This is the part most guides get wrong or skip.

**Section 16(4)** says a registered person cannot take input tax credit on an **invoice or debit note** after **30 November** following the end of the financial year to which it relates, or the date of filing the annual return, **whichever is earlier**. (The date was the September return until the Finance Act 2022 moved it to 30 November, from 1 October 2022.)

Before **1 January 2021**, the section said "invoice relating to such debit note". So the credit on a debit note was tied to the **original invoice's** year, and a debit note issued late in the following year could lose its credit entirely. The **Finance Act 2020** removed those words with effect from 1 January 2021.

**CBIC Circular 160/16/2021-GST** (20 September 2021) then clarified: for debit notes, the **date of issue of the debit note**, not the date of the underlying invoice, decides the relevant financial year for Section 16(4). Its illustration is an invoice of 16 March 2021 and a debit note of 7 July 2021: the invoice belongs to FY 2020-21, but the debit note's credit is governed by FY 2021-22.

| Original invoice | Debit note issued | ITC deadline for the debit note |
| --- | --- | --- |
| 25 February 2026 (FY 2025-26) | 10 April 2026 (FY 2026-27) | 30 November 2027, or annual return date for 2026-27 if earlier |
| 15 June 2026 (FY 2026-27) | 20 September 2026 (FY 2026-27) | 30 November 2027, or annual return date for 2026-27 if earlier |

The usual Section 16(2) conditions still apply, including the debit note showing in GSTR-2B. See our guide to [input tax credit](https://billzap.app/blog/input-tax-credit-gst).

### What the buyer does in IMS

Debit notes reported by the supplier appear on the buyer's **Invoice Management System (IMS)** dashboard. Accepted, or left without action, they flow into GSTR-2B and the credit is claimed in GSTR-3B; marked pending, they wait; rejected, they stay out of his credit. See our [GSTR-2B guide](https://billzap.app/blog/gstr-2b).

## The buyer's "debit note" for purchase returns

When you return goods, you send the supplier a note saying "we have debited your account": in accounting, a **debit note**. Accounting software often names the purchase return voucher "Debit Note" too.

Under GST, that document has **no tax effect**:

- It is issued by the **buyer**, but Section 34 only lets the **supplier** issue GST debit or credit notes.
- It is **not reported in GSTR-1** by anyone.
- For the return to reduce GST, the **supplier** must issue a **credit note** under Section 34(1), within the 30 November deadline. The buyer then reverses the matching credit. See our guide to the [credit note in GST](https://billzap.app/blog/credit-note-in-gst).

So send your purchase return note, but chase **the supplier's credit note**. Without it, his tax and your credit stay as they were. Where his credit note deadline has passed, some businesses treat the return as a fresh sale by the buyer on his own tax invoice; agree that with your CA first.

| | Supplier's GST debit note | Buyer's purchase return "debit note" |
| --- | --- | --- |
| Issued by | Supplier | Buyer |
| Law | Section 34(3), Rule 53(1A) | None (commercial document) |
| Effect on GST | Increases supplier's tax, buyer gets more credit | None |
| Reported in GSTR-1 | Yes, Table 9B | No |
| Correct GST document for a return | | Supplier's **credit note** |

## Where BillZap fits

BillZap is a billing app for your sales, and it **does not issue debit notes or credit notes**. Use your accounting software or a numbered manual book with the Rule 53(1A) fields above. What BillZap does is help you avoid the short billing that leads to debit notes: HSN codes and GST rates saved on each product, CGST, SGST or IGST worked out on every bill, automatic numbering, and a GSTR-1 file export for your CA. It is free, needs no sign-up and works offline on Android.

[[cta: Bill the right rate the first time | Save each product with its HSN code and GST rate, and BillZap works out CGST, SGST or IGST on every bill, then exports a GSTR-1 file for your CA. Free, no sign-up.]]

## FAQ

### What is a debit note in GST?

A document issued by a registered supplier under Section 34(3) of the CGST Act to increase the taxable value or tax of an earlier tax invoice, for example after a price increase, short billing or a lower tax rate charged by mistake. A supplementary invoice is treated as a debit note.

### Is there a time limit for issuing a debit note under GST?

Section 34 sets no deadline for issuing a debit note. You report it in GSTR-1 for the month it is issued and pay the extra tax in that month's GSTR-3B. The time limit that matters is the buyer's: Section 16(4) for claiming credit.

### Till when can the buyer claim ITC on a debit note?

Until 30 November after the end of the financial year in which the debit note was issued, or the date of filing the annual return for that year, whichever is earlier. Since 1 January 2021 the debit note's own date decides the year, not the original invoice's date (Circular 160/16/2021-GST).

### Who issues a debit note, the buyer or the seller?

Under GST, only the seller (supplier). A buyer's "debit note" for returned goods is an accounting document with no GST effect. The seller must issue a credit note for the return.

### In which table of GSTR-1 is a debit note reported?

Table 9B, "Credit/Debit Notes", in the return for the month the debit note is issued. Amendments go in Table 9C, and the series is shown in Table 13.

### Can one debit note cover several invoices?

Yes. Section 34(3) refers to "one or more tax invoices", so a single debit note can cover several invoices to the same buyer, as long as it lists each original invoice number and date.

### Does BillZap issue debit notes?

No. BillZap makes tax invoices, bills of supply and plain bills for your sales. Debit and credit notes need your accounting software or a manual book.

## The bottom line

If your invoice came out **short**, the supplier issues a **debit note**, reports it in **GSTR-1 Table 9B** for the month of issue, and pays the extra tax with that month's GSTR-3B. There is no issue deadline, and the buyer's credit deadline runs from the **debit note's date**. If goods are coming **back**, you need the supplier's credit note instead.

*This guide explains debit notes under GST in plain language and is not tax advice. Confirm your own case with your chartered accountant before you file.*
