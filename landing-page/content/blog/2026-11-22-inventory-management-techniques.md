---
title: Inventory Management Techniques for Small Shops: FIFO, ABC, Reorder Level, Safety Stock and EOQ With Kirana Numbers
slug: inventory-management-techniques
meta_title: Inventory Management Techniques: FIFO, ABC, Reorder Level
meta_desc: Inventory management techniques for shops: FIFO, FEFO, ABC analysis, reorder level, safety stock, EOQ, turnover ratio and dead stock, with kirana numbers.
focus_keyword: inventory management techniques
secondary_keywords: [fifo lifo, abc analysis, reorder level formula, safety stock, dead stock, inventory turnover ratio, inventory management for small business]
tags: [Kirana, Small business, Calculations]
excerpt: The inventory management techniques that actually work in an Indian shop, each with worked kirana numbers: FIFO and FEFO (and why LIFO is not allowed under Indian accounting standards), ABC analysis, reorder level and safety stock, EOQ, inventory turnover ratio and days, dead stock clearance and cycle counts.
publish_at: 2026-11-22T09:00:00+05:30
author: Dakshesh B
---

Most pages on inventory management techniques are written for warehouses, or by software companies selling an inventory module. They define FIFO, ABC and EOQ in textbook language with dollar examples, and leave a kirana or medical store owner wondering which of these is worth doing on a busy Tuesday.

This guide works each technique through with numbers from a real-sized Indian shop: what it is, the formula, an example, and how much effort it takes. It also corrects a common mistake: **LIFO is not an allowed costing method for financial statements in India.**

## Quick answer

The techniques that matter most for a small shop, in the order to adopt them:

1. **FIFO / FEFO:** sell the oldest stock first, or the stock that expires first for food and medicines.
2. **Reorder level** = average daily sales × lead time in days + safety stock.
3. **Safety stock** = (maximum daily sales × maximum lead time) − (average daily sales × average lead time).
4. **ABC analysis:** rank items by yearly value; the few "A" items carrying 70 to 80% of value get the closest watch.
5. **Cycle counts:** count A items weekly, B monthly, C quarterly.
6. **Inventory turnover ratio** = cost of goods sold ÷ average inventory; **inventory days** = 365 ÷ turnover.
7. **Dead stock review:** anything unsold for 90 to 180 days gets returned, bundled or discounted.
8. **EOQ** = √(2 × annual demand × cost per order ÷ holding cost per unit per year), as a check on order size.

For valuing stock in your books, Indian standards (AS 2 and Ind AS 2) allow **FIFO or weighted average cost**, not LIFO.

## 1. FIFO and FEFO: which unit leaves first

**FIFO (first in, first out):** new deliveries go to the back of the shelf and older stock is pulled forward. It cuts expiry, fading and damage.

**FEFO (first expired, first out):** for anything with an expiry date, the unit with the nearest expiry goes first, even if it arrived later, because a newer delivery sometimes expires sooner than older stock. Medical stores, dairy, bakery items, packaged foods and cosmetics should run FEFO; see [how to start a medical store](https://billzap.app/blog/how-to-start-a-medical-store) for why it matters most there.

**Practical setup:** write the expiry month in marker on each carton as it arrives, keep a "near expiry" basket at the counter, and check dairy and bread daily, packaged food weekly and medicines monthly.

### FIFO, LIFO and weighted average: valuing your stock

The same letters are also a **costing method**: which purchase price you use for goods sold and stock left.

Example: sunflower oil. Opening stock is 20 pouches bought at ₹140; you buy 30 more at ₹150, and sell 35.

| Method | Cost of 35 pouches sold | Value of 15 pouches left |
| --- | --- | --- |
| **FIFO** | 20 × ₹140 + 15 × ₹150 = ₹5,050 | 15 × ₹150 = ₹2,250 |
| **Weighted average** (₹7,300 ÷ 50 = ₹146) | 35 × ₹146 = ₹5,110 | 15 × ₹146 = ₹2,190 |
| LIFO (not allowed in India) | 30 × ₹150 + 5 × ₹140 = ₹5,200 | 15 × ₹140 = ₹2,100 |

Each method splits the same ₹7,300 differently between this period's cost and the stock carried forward. With rising prices, LIFO shows the highest cost and lowest profit.

**LIFO is not permitted under Indian accounting standards.** AS 2 (Valuation of Inventories) and Ind AS 2 (Inventories) allow only **FIFO or weighted average cost** for ordinary interchangeable goods, and specific identification for items that are not interchangeable, such as a particular piece of jewellery. Arrange your shelf as you like, but value stock in your books by FIFO or weighted average, consistently, at cost and not MRP, as our [stock register format](https://billzap.app/blog/stock-register-format) guide explains.

## 2. Reorder level and safety stock

Running out of a fast seller costs the sale, and often the customer. The reorder level tells you **when** to order so the delivery arrives before the shelf is empty.

**Reorder level = average daily sales × lead time (days) + safety stock**

**Safety stock = (maximum daily sales × maximum lead time) − (average daily sales × average lead time)**

### Worked example: toor dal in a kirana

| Input | Value |
| --- | --- |
| Average daily sales | 9 packets |
| Maximum daily sales (Sundays, month start) | 12 packets |
| Average lead time (order to delivery) | 2 days |
| Maximum lead time (when the distributor is late) | 3 days |

- Safety stock = (12 × 3) − (9 × 2) = 36 − 18 = **18 packets**
- Reorder level = (9 × 2) + 18 = **36 packets**

When shelf and godown together hold 36 packets, order. In two normal days you sell about 18 and still have the 18-packet buffer when the delivery comes.

To avoid overbuying, add a **maximum level = reorder level + order quantity − (minimum daily sales × minimum lead time)**. Ordering 50 at a time, selling at least 6 a day, with a fastest delivery of 1 day: 36 + 50 − 6 = **80 packets**. Anything above 80 is idle money.

**Adjust for seasons.** Raise reorder levels two to three weeks before Diwali, Eid, weddings or school reopening, using last year's bills for the same weeks, and lower them after.

## 3. ABC analysis: put your attention where the money is

ABC ranks items by **annual consumption value** (units sold a year × cost price): **A** items make up roughly 70 to 80% of value, **B** the next 15 to 20%, and **C** the long tail.

### Worked example: ten items from a kirana

| Item | Cost (₹) | Units a year | Annual value (₹) | Share | Cumulative | Class |
| --- | --- | --- | --- | --- | --- | --- |
| Toor dal (1 kg) | 128 | 3,200 | 4,09,600 | 26.5% | 26.5% | A |
| Sunflower oil (1 L) | 145 | 1,800 | 2,61,000 | 16.9% | 43.3% | A |
| Sugar (kg) | 42 | 6,000 | 2,52,000 | 16.3% | 59.6% | A |
| Wheat atta (5 kg) | 225 | 1,100 | 2,47,500 | 16.0% | 75.6% | A |
| Basmati rice (5 kg) | 520 | 300 | 1,56,000 | 10.1% | 85.6% | B |
| Tea (250 g) | 120 | 700 | 84,000 | 5.4% | 91.1% | B |
| Glucose biscuits | 22 | 3,600 | 79,200 | 5.1% | 96.2% | C |
| Bath soap (100 g) | 32 | 1,100 | 35,200 | 2.3% | 98.5% | C |
| Incense sticks | 25 | 600 | 15,000 | 1.0% | 99.4% | C |
| Matchboxes (10 pack) | 10 | 900 | 9,000 | 0.6% | 100.0% | C |
| **Total** | | | **15,48,500** | | | |

Four items carry three-quarters of the money. In a real shop with 500 items, the A group is a small fraction of the list: you cannot watch 500 items closely, but you can watch 40.

| | A items | B items | C items |
| --- | --- | --- | --- |
| Reorder level | Calculated, reviewed monthly | Calculated, reviewed quarterly | Rough rule ("order when one box is left") |
| Stock count | Weekly | Monthly | Quarterly |
| Supplier terms | Negotiate rate and credit | Compare two suppliers | Buy from whoever visits |

Biscuits sell 3,600 packets a year yet land in C because each costs little: ABC is about money, not busyness. Pair it with **FSN** (fast, slow, non-moving) to catch slow lines, and medical stores with **VED** (vital, essential, desirable) so a vital medicine is never out of stock even if its value is small.

[[cta: Know the moment an A item runs low | In BillZap each product keeps a stock count that drops as you bill, with a low-stock alert so you reorder before the shelf is empty. Free, works offline, no sign-up.]]

## 4. EOQ: how much to order each time

Order too often and you waste time and delivery charges; order too much and money sits on the shelf. **Economic order quantity** finds the balance:

**EOQ = √(2 × D × S ÷ H)**, where D is units sold a year, S the cost of placing one order (time, transport, delivery charge) and H the cost of holding one unit for a year (interest, space, damage), commonly taken as 15 to 25% of the item's cost.

**Example: sunflower oil.** D = 1,800 pouches (5 a day), S = ₹150 an order, H = 20% of ₹145 = ₹29.

EOQ = √(2 × 1,800 × 150 ÷ 29) = √(5,40,000 ÷ 29) = √18,621 = **about 136 pouches**, or 1,800 ÷ 136 = about **13 orders a year**, roughly every four weeks.

**Treat EOQ as a check, not a rule.** It assumes steady demand and no price breaks. In a real shop the salesman visits weekly anyway, a scheme may give a free case on 10 cartons, and shelf life limits what you can hold. If you order oil weekly in lots of 35, EOQ says bigger, less frequent orders would cost less, if you have space and the stock will not expire.

## 5. Inventory turnover ratio and inventory days

**Inventory turnover ratio = cost of goods sold ÷ average inventory**, where **average inventory = (opening stock + closing stock) ÷ 2**, and **inventory days = 365 ÷ turnover**.

**Whole shop:** cost of goods sold for the year ₹36,00,000; stock ₹2,40,000 on 1 April and ₹3,60,000 on 31 March.

- Average inventory = (₹2,40,000 + ₹3,60,000) ÷ 2 = **₹3,00,000**
- Turnover = ₹36,00,000 ÷ ₹3,00,000 = **12 times a year**
- Inventory days = 365 ÷ 12 = **about 30 days**

A rupee spent on stock comes back as a sale in about a month, on average. The detail is in the items:

| Item | Yearly cost of goods sold | Average stock | Turnover | Days |
| --- | --- | --- | --- | --- |
| Toor dal | ₹4,09,600 | 35 × ₹128 = ₹4,480 | 91 times | 4 days |
| Bath soap | ₹35,200 | 30 × ₹32 = ₹960 | 37 times | 10 days |
| Incense sticks | ₹15,000 | 120 × ₹25 = ₹3,000 | 5 times | 73 days |

The incense sticks tie up ₹3,000 for over two months. Cutting stock to 30 packets frees ₹2,250 for toor dal, which turns every four days.

There is no single "good" ratio: dairy turns daily, hardware far slower. Compare each category with its own past months and watch the trend. Use cost of goods sold, not sales, or the ratio flatters you; our [profit margin formula](https://billzap.app/blog/profit-margin-formula) guide shows how to work it out.

## 6. Dead stock: find it and clear it

**Dead stock** has not sold for a long time and will not sell at full price: last year's festival items, a flavour nobody liked, covers for an old phone model. A practical cut-off is no sale in **90 days** for packaged goods and **180 days** for durables. Once a month, list items whose count has not moved and anything within two months of expiry.

**Clear it, in order of preference:**

1. **Return or exchange** with the distributor; many FMCG companies adjust near-expiry stock if you ask before it expires.
2. **Bundle** it with a fast seller.
3. **Discount** it: 40 pieces bought at ₹150 (₹6,000) and sold at ₹105 bring back ₹4,200 to spend on stock that sells. 70% now beats nothing later.
4. **Sell to a clearance trader**, or donate items still safe to use.

**Tax point:** a regular GST taxpayer who claimed input tax credit on goods later destroyed, written off or given away generally has to reverse that credit. Record write-offs with date and reason for your CA; see [input tax credit](https://billzap.app/blog/input-tax-credit-gst).

**Prevent it:** buy new items in small quantities first and skip "free case" schemes on slow sellers.

## 7. Cycle counting instead of one big annual count

A once-a-year full count means closing the shop, and errors found in March may have started in June. **Cycle counting** spreads it out:

| Class | How often | Example in a kirana |
| --- | --- | --- |
| A | Every week | Oil, dal, sugar, atta, costly items |
| B | Every month | Rice, tea, dry fruits, shampoo |
| C | Every quarter | Matchboxes, incense, stationery |

Count before opening or after closing, shelf and godown both, and **write down each difference with a reason** (damaged, expired, spilt, not billed) instead of quietly correcting the figure. Small losses on loose items are normal; a growing gap on one packaged item points to unbilled sales or theft. Still do a full count at year-end for your closing stock.

## Common mistakes

- **Not billing every sale:** the stock record goes wrong and your real turnover is hidden.
- **Valuing stock at MRP** instead of cost.
- **One reorder level all year,** ignoring festivals and school reopening.
- **Mixing units:** fix the conversion (1 carton = 48 soaps).
- **Buying for the scheme, not the shelf:** a free case is worth nothing if it expires.

For keeping fast movers in stock, see [increasing kirana store sales](https://billzap.app/blog/increase-kirana-store-sales).

## Where BillZap fits

BillZap is a free billing app for Android, not a full inventory system. Each product carries a **stock count** that goes down as you bill, with a **low-stock alert** when it runs low, which covers the "sold" side and the reorder warning. Add a buying price to see each product's margin; reports show sales, GST collected and profit, exportable as PDF or CSV.

It does **not** do barcode scanning, batch or expiry tracking, purchase bills or size and colour variants, so keep expiry dates, deliveries and cycle-count differences in your own register. For choosing a counter app, see the [kirana store billing app](https://billzap.app/blog/kirana-store-billing-app) guide, or try BillZap at [billzap.app/try](https://billzap.app/try).

[[cta: Stock that counts itself down as you sell | BillZap is free billing for Android shops: stock count per product, low-stock alerts, buying price and margin, and reports with sales and profit. Works offline, no sign-up.]]

## FAQ

### What are the main inventory management techniques?

FIFO and FEFO, reorder level and safety stock, ABC analysis, EOQ, inventory turnover ratio, dead stock review and cycle counting. A small shop should start with FEFO, reorder levels for fast movers and weekly counts of top items.

### What is the reorder level formula?

Reorder level = average daily sales × lead time in days + safety stock. Selling 9 a day, with a 2-day delivery and 18 as safety stock, the reorder level is 36.

### How do I calculate safety stock?

(Maximum daily sales × maximum lead time) − (average daily sales × average lead time). With 12 and 3 days at most, and 9 and 2 days on average, safety stock is 36 − 18 = 18 units.

### Is LIFO allowed in India?

Not for financial statements. AS 2 and Ind AS 2 allow FIFO or weighted average cost for interchangeable goods, and specific identification for items that are not interchangeable.

### What is a good inventory turnover ratio for a kirana store?

There is no single benchmark. Staples may turn every few days and slow lines take months. Work it out by item or category and compare with your own past months.

### What is ABC analysis in inventory?

Ranking items by yearly value (units sold × cost): A items carry about 70 to 80% of value and get the closest control, B the next 15 to 20%, and C the small remainder.

### How do I get rid of dead stock?

Return or exchange it with the distributor if you can, bundle it with fast sellers, discount it or sell to a clearance trader. Recovering part of the cost now beats holding it until it expires.

## The bottom line

You do not need software or an MBA to manage stock well. Sell the soonest-expiring unit first, set reorder levels with sensible safety stock for fast movers, use ABC to decide where your attention goes, count A items weekly and review dead stock monthly. Value stock at cost by FIFO or weighted average. Done consistently, you run out less, throw away less and keep more cash for stock that sells.

*This guide explains inventory techniques in plain language and is not accounting or tax advice. Confirm valuation and GST treatment of write-offs with your chartered accountant.*
