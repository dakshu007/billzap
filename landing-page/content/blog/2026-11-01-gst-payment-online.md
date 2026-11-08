---
title: GST Payment Online: Create a Challan, Pay by UPI or Net Banking, and Fix the Common Mistakes
slug: gst-payment-online
meta_title: GST Payment Online: Create Challan, Pay by UPI, Fix Errors
meta_desc: How to make GST payment online: create a PMT-06 challan, pay by UPI, net banking, card or NEFT, use your cash ledger and fix wrong-head payments.
focus_keyword: gst payment online
secondary_keywords: [how to pay gst online, gst challan, pmt-06, create challan gst portal, cpin, gst payment by upi, electronic cash ledger]
tags: [GST guides, Returns, Payments]
excerpt: A practical guide to paying GST online: who pays and by when, creating a PMT-06 challan before or after login, CPIN and CIN, every payment mode and its limits, how the cash and credit ledgers work in GSTR-3B, interest with a worked example, and what to do when you pay under the wrong head or the money leaves your bank but never reaches the portal.
publish_at: 2026-11-01T09:00:00+05:30
author: Dakshesh B
---

The pages that rank for "GST payment online" are mostly click-by-click tours of the GST portal: log in, go to Services, click Create Challan, pick a bank. That part is easy. What trips up shop owners is everything around it: how much to put in the challan once input tax credit is counted, which head the money goes under, why paying the challan does not finish the job, and what to do when ₹30,000 leaves the bank and never shows up on the portal.

This guide covers the steps and then those gotchas.

## Quick answer

- **Where:** only on the GST portal. Go to **Services > Payments > Create Challan** (with or without logging in), fill the amount under IGST, CGST, SGST/UTGST or cess, and generate the challan in **Form GST PMT-06**.
- **How:** net banking or credit/debit card through an authorised bank, **UPI or IMPS from any bank**, **NEFT/RTGS** from any bank with a mandate form, or **over the counter** at an authorised bank for up to **₹10,000 per challan per tax period**.
- **Challan validity:** the challan number (**CPIN**) is valid for **15 days**. Once the bank confirms the money, you get a **CIN** and the amount lands in your **electronic cash ledger**.
- **The step people miss:** money in the cash ledger is not yet "tax paid". It is used up only when you **file GSTR-3B** (or CMP-08) and offset the liability.
- **When:** monthly filers by the **20th**; QRMP filers by the **25th** for the first two months of a quarter; composition dealers by the **18th** after the quarter.
- **Late:** **18% a year** interest on the cash portion, counted day by day.

## Who pays GST, and by when

| How you are registered | How you pay | Due date |
| --- | --- | --- |
| **Regular, monthly filer** | Through GSTR-3B for the month | 20th of the next month |
| **Regular, QRMP** (turnover up to ₹5 crore) | PMT-06 challan for months 1 and 2 of the quarter, then GSTR-3B for the quarter | 25th of the next month for months 1 and 2; GSTR-3B on the 22nd or 24th after the quarter |
| **Composition dealer** | Through CMP-08 for the quarter | 18th of the month after the quarter |

The full calendar, including which states file on the 22nd and which on the 24th, is in our guide to [GST due dates](https://billzap.app/blog/gst-due-dates).

### The QRMP choice: 35% challan or self-assessment

If you file quarterly, the portal gives you two ways to pay for the first two months of each quarter. When you create the challan, pick **Monthly payment for quarterly return** as the reason, then:

- **35% challan (fixed sum).** The portal fills in the amount itself: 35% of the tax you paid in cash in your last quarterly GSTR-3B, or 100% of the cash tax in your last monthly GSTR-3B if you have just moved to QRMP. You cannot edit it. Good when your sales are steady.
- **Self-assessment.** You work out this month's actual tax after input tax credit and pay that. Better when sales swing, for example a big festive month followed by a quiet one.

If you have no tax to pay for the month, or your cash and credit balances already cover it, **you do not need to create a challan at all**. Whatever you pay in months 1 and 2 sits in your cash ledger and is adjusted when you file the quarterly GSTR-3B.

Composition dealers have no input tax credit to set off, so the whole CMP-08 amount is paid in cash. Our guide to the [GST composition scheme](https://billzap.app/blog/gst-composition-scheme) has the rates.

## First, work out how much cash to pay

You never pay your full output tax in cash. You pay **output tax minus input tax credit**, and the credit must be used in a fixed order. Two ledgers matter:

| | Electronic cash ledger | Electronic credit ledger |
| --- | --- | --- |
| **What goes in** | Money you deposit through challans | Input tax credit on your purchases, from GSTR-2B |
| **What it can pay** | Tax, interest, late fee, penalty, anything | Output tax only |
| **Can you move it between heads?** | Yes, with PMT-09 | No |
| **Can it be refunded?** | Excess balance, yes, by a refund claim | Only in specific cases (exports, inverted duty) |

**The set-off order.** IGST credit is used first, for IGST, and any balance can then go towards CGST or SGST. CGST credit can pay CGST and then IGST. SGST credit can pay SGST and then IGST. **CGST credit can never pay SGST, and SGST credit can never pay CGST.** Whatever is left after credit is your cash payment.

**A worked example.** A shop in Maharashtra has these figures for October:

| Head | Output tax | Credit available | Credit used | Paid in cash |
| --- | --- | --- | --- | --- |
| IGST | ₹5,000 | ₹8,000 | ₹5,000 (from IGST) | ₹0 |
| CGST | ₹30,000 | ₹12,000 | ₹12,000 (CGST) + ₹3,000 (left-over IGST) | ₹15,000 |
| SGST | ₹30,000 | ₹12,000 | ₹12,000 (SGST) | ₹18,000 |
| **Total** | **₹65,000** | **₹32,000** | **₹32,000** | **₹33,000** |

The ₹3,000 of IGST credit left after paying IGST could equally be split between CGST and SGST (say ₹1,500 each, giving cash of ₹16,500 under each). Either way the total cash is ₹33,000; what changes is how much goes under each head in the challan. **Do this split before you create the challan**, because the challan amount is locked once it is generated.

Which purchases give you credit is covered in our guide to [input tax credit](https://billzap.app/blog/input-tax-credit-gst).

## How to create a GST challan on the portal

You can create a challan **after logging in** or **without logging in**. Both reach the same payment options.

| | Post-login | Pre-login |
| --- | --- | --- |
| **Where** | Log in, then Services > Payments > Create Challan | gst.gov.in > Services > Payments > Create Challan, enter GSTIN and captcha |
| **Save a draft challan** | Yes (kept for 7 days) | No |
| **See your cash ledger balance** | Yes | No |
| **Challan history** | Yes | Track it under Services > Payments > Track Payment Status |
| **Best for** | The business owner or CA | Paying for someone else, or when the login is not handy |

The steps after logging in:

1. Go to **Services > Payments > Create Challan**.
2. Choose the **reason**: *Monthly payment for quarterly return* (QRMP, months 1 and 2) or *Any other payment* (everyone else, and for interest or late fee).
3. Enter amounts in the grid. Columns are the **major heads** (IGST, CGST, SGST/UTGST, cess). Rows are the **minor heads** (tax, interest, penalty, fees, others). Put tax under *tax* and interest under *interest*.
4. Choose a **payment mode** (next section) and click **Generate Challan**.
5. Note the **CPIN** on the challan and pay before it expires.
6. When the bank confirms, the challan shows a **CIN** and the amount appears in your electronic cash ledger. Download the paid challan as your receipt.

There is also a shortcut: while filing GSTR-3B, if your cash ledger is short, the payment section offers **Create Challan** with the shortfall already filled in by head. For most monthly filers this is the least error-prone route.

## Payment modes, and their limits

Rule 87 of the CGST Rules lists the modes allowed:

| Mode | From which bank | Things to know |
| --- | --- | --- |
| **Net banking** | Authorised banks listed on the payment page | Fastest; CIN usually comes back at once |
| **UPI** | Any bank (UPI ID must be supported) | The portal says UPI and card payment was rolled out state by state, so check the option appears for your state |
| **IMPS** | Any bank | Works like NEFT/RTGS, with a mandate form |
| **Credit or debit card** | Through an authorised bank | Any bank's Visa, Mastercard or RuPay card; Diners credit cards. Any charge is borne by you |
| **NEFT or RTGS** | Any bank | Download the **mandate form** with the challan and give it to your bank, or enter its details in your bank's net banking. Valid 15 days |
| **Over the counter** | Authorised banks | Cash, cheque or demand draft, **up to ₹10,000 per challan per tax period**. One cheque per challan |

A challan made for over-the-counter payment cannot be paid online later. NEFT or RTGS credit can take hours, so avoid them on the due date.

## CPIN, CIN and BRN, and why your challan amount is locked

- **CPIN** (Common Portal Identification Number): the 14-digit number given when you generate the challan. Valid for **15 days**; after that you cannot pay against it.
- **CIN** (Challan Identification Number): generated by the bank when the money reaches the government account. A CIN is proof of payment, and it is what credits your cash ledger.
- **BRN** (Bank Reference Number): your bank's own transaction number for the payment.

Once a CPIN is generated, the amount cannot be changed at the bank, and a challan **cannot be cancelled**. If the amount is wrong, create a fresh challan; the unused one expires after 15 days.

[[cta: Know the exact tax before you open the challan | BillZap adds up GST collected on every bill, split into CGST, SGST and IGST, so the figure you put in the challan comes straight from your sales report.]]

## Paying the challan is not the end: offset in GSTR-3B

After the challan is paid, the money sits in your **electronic cash ledger** as a balance. Your tax liability is cleared only when you **file GSTR-3B** (or CMP-08), where the portal debits the cash ledger and credit ledger against what you owe.

In GSTR-3B, after entering your sales and input tax credit, you reach **Payment of tax**. The portal suggests how much to take from credit and how much from cash for each head. Check the split against your working (the example above), then click **Make payment / Post credit to ledger** and file the return. If the cash balance is short, the portal shows the shortfall and lets you create a challan right there.

Details of each table are in our [GSTR-3B guide](https://billzap.app/blog/gstr-3b). Remember that the tax figure in GSTR-3B now comes from your GSTR-1, so your sales return has to be right first; see [how to file GSTR-1](https://billzap.app/blog/how-to-file-gstr-1).

## Interest on late payment, with a worked example

Interest is **18% a year** on the tax paid in cash after the due date, worked out day by day. It is paid in cash, under the *interest* row of each head, and cannot be paid from input tax credit.

**Example.** Take the shop above: ₹33,000 to be paid in cash for October, due **20 November**. It files and pays on **30 November**, 10 days late.

| Item | Working | Amount |
| --- | --- | --- |
| Interest | ₹33,000 × 18% × 10 ÷ 365 | ₹162.74 |
| Late fee for GSTR-3B | 10 days × ₹50 (₹25 CGST + ₹25 SGST) | ₹500.00 |
| **Cost of filing 10 days late** | | **₹662.74** |

**A useful rule most guides skip.** Under Rule 88B, if the money was **already in your cash ledger on or before the due date** and stayed there until you filed, **no interest is charged on that amount**, even if the return itself is late. So if this shop had paid a challan for ₹33,000 on 19 November but could only file on 30 November, the interest would be **nil**. The ₹500 late fee for filing late would still apply.

## Common mistakes and how to fix them

### Paid under the wrong head

You paid ₹18,000 under CGST when it should have been SGST, or put tax money under the *interest* row. Nothing is lost. Use **Form GST PMT-09**: **Services > Ledgers > Electronic Cash Ledger > File GST PMT-09 For Transfer of Amount**. It moves money between major heads (IGST, CGST, SGST, cess) and minor heads (tax, interest, fee and so on) within your cash ledger. Do it before filing GSTR-3B so the balance sits where the return needs it.

PMT-09 works only on the **cash** ledger. It cannot move input tax credit, so a credit balance stuck under one head stays there.

### Paid twice, or paid too much

The extra money stays in your cash ledger. You can use it next month or for interest and late fee, or claim it back as a refund of excess cash ledger balance.

## Money debited, but no CIN or ledger credit

This happens with net banking timeouts and UPI failures. What to do, in order:

1. **Do not pay again straight away.** Open **Challan History** (after login) or **Track Payment Status** (before login) and check the CPIN's status. Payments sometimes show as in progress and update a little later.
2. **Check with your bank.** If the transaction failed at the bank's end, the bank usually reverses it to your account.
3. **If the money left your account but no CIN appears**, raise a grievance in **Form GST PMT-07** under **Services > Payments > Grievance against Payment (GST PMT-07)**, quoting the CPIN, date, amount and your bank reference number. The rules also let the portal update your cash ledger from the Reserve Bank's records when the bank fails to send the CIN.
4. **If the due date is close**, pay through a fresh challan and treat the stuck amount as excess once it arrives. Keep screenshots of the debit.

[[cta: Walk into the 20th with the numbers ready | BillZap is free GST billing on Android: every bill numbered, HSN codes and CGST, SGST or IGST worked out, plus reports and a GSTR-1 file export for your CA. No sign-up, works offline.]]

## Where BillZap fits

BillZap does not pay GST or file returns; challans and GSTR-3B happen on the GST portal. What it does is make the numbers you take there reliable. Every bill gets an automatic number, the right heading (Tax Invoice, Bill of Supply or Bill), HSN codes and the CGST, SGST or IGST split. At month end, the reports show sales and GST collected and export as PDF or CSV, and the GSTR-1 file export goes to your CA. That gives you the output tax for the challan; input tax credit still comes from your purchase bills and GSTR-2B.

## FAQ

### Can I pay GST by UPI?

Yes. The rules allow UPI from any bank, and the GST portal shows UPI as an e-payment option. It was rolled out state by state, so if you do not see it, use net banking or NEFT/RTGS instead.

### How long is a GST challan valid?

The CPIN is valid for 15 days from the date the challan is generated, and so is the NEFT/RTGS mandate form. After that, create a new challan.

### Can I pay GST in cash at the bank?

Yes, over the counter at an authorised bank, but only up to ₹10,000 per challan per tax period, by cash, cheque or demand draft.

### I paid GST under CGST instead of IGST. What now?

File Form GST PMT-09 from your electronic cash ledger to move the amount from CGST to IGST. It works for any major or minor head within your own cash ledger.

### Is GST paid once the challan is paid?

Not fully. The money goes into your electronic cash ledger. The liability is cleared only when you file GSTR-3B or CMP-08 and the portal debits the ledger.

### What is the interest rate on late GST payment?

18% a year on the tax paid in cash after the due date, calculated per day. No interest is charged on money that was already in your cash ledger by the due date and stayed there until you filed.

## The bottom line

Work out your cash figure after input tax credit, create the challan with the right split across heads, pay before the CPIN expires, then file GSTR-3B so the money is actually used. Pay on time even if the return is late, fix a wrong head with PMT-09, and use PMT-07 rather than paying twice.
