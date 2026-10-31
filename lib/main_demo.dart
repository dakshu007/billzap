// lib/main_demo.dart — the app with a demo shop already set up.
//
// Two uses:
//   - The browser demo at billzap.app/try, built by the landing-page
//     deploy with `flutter build web -t lib/main_demo.dart`.
//   - Play Store screenshots, from the same build.
// It seeds a believable kirana store (business, catalogue, customers,
// six months of invoices, expenses), then starts the normal app with
// demo mode on (lib/demo/demo_mode.dart). Every visit starts from a
// fresh shop, named after the visitor's business when the page passes
// one as ?shop=. Release builds use lib/main.dart and never include
// this file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'i18n/translations.dart';
import 'demo/demo_mode.dart';
import 'main.dart' show BillZapApp;
import 'models/models.dart';
import 'personal/spending_store.dart' show kSpendingBox;
import 'providers/providers.dart';
import 'services/app_lock_service.dart';
import 'services/local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  kDemoMode = true;
  await Hive.initFlutter();
  // A fresh shop on every visit: whatever the last visitor (or this one,
  // last time) typed into the demo is gone.
  for (final box in ['billzap_v1', 'catalog', 'settings', kSpendingBox]) {
    try {
      await Hive.deleteBoxFromDisk(box);
    } catch (_) {}
  }
  await LocalStorage.instance.init();
  await AppLockService.instance.init();
  try {
    await Hive.openBox('settings');
  } catch (_) {}
  try {
    initGlobalLanguage();
  } catch (_) {}

  if (LocalStorage.instance.getBusiness() == null) await _seed();

  // The newest bill is preselected so /#/preview opens on it.
  final container = ProviderContainer();
  final invoices = LocalStorage.instance.getInvoices()
    ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
  if (invoices.isNotEmpty) {
    container.read(selectedInvoiceProvider.notifier).select(invoices.first);
  }

  runApp(UncontrolledProviderScope(container: container, child: const BillZapApp()));
}

Future<void> _seed() async {
  final s = LocalStorage.instance;
  final now = DateTime.now();

  await s.saveBusiness(Business(
    name: _shopName(),
    gstin: '33ABCPL4821K1Z7',
    phone: '98940 12345',
    address: '24, Gandhi Road, R.S. Puram',
    city: 'Coimbatore',
    state: 'Tamil Nadu',
    stateCode: '33',
    pincode: '641002',
    bankName: 'State Bank of India',
    accountNumber: '3289 0045 1172',
    ifscCode: 'SBIN0001234',
    upiId: 'srilakshmi.demo@upi',
    invoicePrefix: 'SLS-',
    nextInvoiceNumber: 1001,
  ));

  // Rates as they stand after the 22 September 2025 GST reform.
  final products = <Product>[
    Product(name: 'Basmati Rice 5 kg', hsnCode: '1006', unit: 'Bag', price: 649, gstRate: 5, cost: 560, stock: 42, lowStockAt: 10),
    Product(name: 'Sunflower Oil 1 L', hsnCode: '1512', unit: 'Nos', price: 155, gstRate: 5, cost: 132, stock: 60, lowStockAt: 15),
    Product(name: 'Toor Dal 1 kg', hsnCode: '0713', unit: 'Pkt', price: 168, gstRate: 5, cost: 145, stock: 6, lowStockAt: 10),
    Product(name: 'Filter Coffee 500 g', hsnCode: '0901', unit: 'Pkt', price: 285, gstRate: 5, cost: 240, stock: 24, lowStockAt: 6),
    Product(name: 'Toothpaste 150 g', hsnCode: '3306', unit: 'Nos', price: 99, gstRate: 5, cost: 82, stock: 48, lowStockAt: 12),
    Product(name: 'Bath Soap (pack of 4)', hsnCode: '3401', unit: 'Pkt', price: 180, gstRate: 5, cost: 150, stock: 30, lowStockAt: 8),
    Product(name: 'Dark Chocolate 100 g', hsnCode: '1806', unit: 'Nos', price: 120, gstRate: 5, cost: 98, stock: 0, lowStockAt: 5),
    Product(name: 'Detergent Powder 1 kg', hsnCode: '3402', unit: 'Pkt', price: 90, gstRate: 18, cost: 68, stock: 75, lowStockAt: 20),
  ];
  for (final p in products) {
    await s.saveProduct(p);
  }

  final kumar = Customer(name: 'Kumar Traders', phone: '98430 55210', gstin: '33AAKFK7731M1Z2', address: '18, Oppanakara Street', city: 'Coimbatore', state: 'Tamil Nadu');
  final anand = Customer(name: 'Anand Super Market', phone: '99001 44871', gstin: '29AAHFA2290B1ZQ', address: '7, 4th Cross, Jayanagar', city: 'Bengaluru', state: 'Karnataka');
  final priya = Customer(name: 'Priya Ramesh', phone: '97888 20431', city: 'Coimbatore', state: 'Tamil Nadu');
  final hotel = Customer(name: 'Hotel Annapoorna', phone: '94431 77802', gstin: '33AAAFH5521D1ZK', address: '3, Avinashi Road', city: 'Coimbatore', state: 'Tamil Nadu');
  final ravi = Customer(name: 'Ravi Krishnan', phone: '90031 66124', city: 'Tiruppur', state: 'Tamil Nadu');
  for (final c in [kumar, anand, priya, hotel, ravi]) {
    await s.saveCustomer(c);
  }

  InvoiceItem item(Product p, double qty) => InvoiceItem(
      name: p.name, hsnCode: p.hsnCode, unit: p.unit, quantity: qty, rate: p.price, gstRate: p.gstRate);

  var n = 1001;
  Future<void> bill(Customer c, int daysAgo, List<InvoiceItem> items,
      {InvoiceStatus status = InvoiceStatus.paid,
      bool interState = false,
      double discount = 0}) async {
    final d = now.subtract(Duration(days: daysAgo));
    await s.saveInvoice(Invoice(
      invoiceNumber: 'SLS-${n++}',
      customerId: c.id,
      customerName: c.name,
      customerPhone: c.phone,
      customerGstin: c.gstin,
      customerAddress: [c.address, c.city].where((x) => x.isNotEmpty).join(', '),
      invoiceDate: d,
      dueDate: d.add(const Duration(days: 15)),
      lineItems: items,
      gstType: interState ? GstType.igst : GstType.cgstSgst,
      placeOfSupply: interState ? 'Karnataka (29)' : 'Tamil Nadu (33)',
      flatDiscount: discount,
      discountBeforeTax: true,
      status: status,
      paidAt: status == InvoiceStatus.paid ? d : null,
      createdAt: d,
    ));
  }

  final p = products;
  // Six months of trade, oldest first, so the revenue chart has a shape.
  await bill(kumar, 170, [item(p[0], 20), item(p[1], 24)]);
  await bill(hotel, 160, [item(p[3], 10), item(p[1], 30)]);
  await bill(anand, 150, [item(p[0], 30), item(p[4], 48)], interState: true);
  await bill(kumar, 135, [item(p[0], 25), item(p[2], 20)]);
  await bill(hotel, 120, [item(p[1], 36), item(p[3], 12), item(p[7], 20)]);
  await bill(anand, 105, [item(p[0], 40), item(p[5], 24)], interState: true);
  await bill(kumar, 92, [item(p[0], 30), item(p[1], 30), item(p[2], 25)]);
  await bill(hotel, 78, [item(p[3], 15), item(p[1], 40)]);
  await bill(priya, 70, [item(p[4], 2), item(p[5], 1), item(p[6], 2)]);
  await bill(anand, 61, [item(p[0], 45), item(p[4], 60), item(p[5], 30)], interState: true);
  await bill(kumar, 48, [item(p[0], 35), item(p[1], 36), item(p[2], 30)]);
  await bill(hotel, 40, [item(p[3], 18), item(p[1], 48), item(p[7], 30)]);
  await bill(ravi, 33, [item(p[7], 6), item(p[4], 3)]);
  await bill(anand, 26, [item(p[0], 50), item(p[5], 36)], interState: true, status: InvoiceStatus.pending);
  await bill(kumar, 18, [item(p[0], 40), item(p[1], 40), item(p[2], 30)]);
  await bill(hotel, 12, [item(p[3], 20), item(p[1], 50)]);
  await bill(anand, 10, [item(p[0], 40), item(p[4], 48)], interState: true);
  await bill(kumar, 8, [item(p[0], 35), item(p[1], 30), item(p[2], 20)]);
  await bill(priya, 6, [item(p[0], 1), item(p[4], 2), item(p[6], 1)]);
  await bill(hotel, 4, [item(p[3], 16), item(p[1], 40), item(p[7], 12)]);
  await bill(kumar, 3, [item(p[0], 30), item(p[3], 10)], status: InvoiceStatus.pending);
  await bill(ravi, 1, [item(p[1], 2), item(p[7], 4)]);
  await bill(hotel, 0, [item(p[0], 4), item(p[1], 6), item(p[3], 2)],
      status: InvoiceStatus.pending, discount: 100);

  final biz = s.getBusiness()!;
  biz.nextInvoiceNumber = n;
  await s.saveBusiness(biz);

  final expenses = <Expense>[
    Expense(category: 'Rent', title: 'Shop rent', amount: 18000, date: now.subtract(const Duration(days: 15)), paymentMode: 'Bank'),
    Expense(category: 'Salary', title: 'Helper salary', amount: 12000, date: now.subtract(const Duration(days: 14)), paymentMode: 'Cash'),
    Expense(category: 'Utilities', title: 'Electricity bill', amount: 3450, date: now.subtract(const Duration(days: 9))),
    Expense(category: 'Transport', title: 'Delivery auto', amount: 850, date: now.subtract(const Duration(days: 2)), paymentMode: 'Cash'),
  ];
  for (final e in expenses) {
    await s.saveExpense(e);
  }
}

/// The visitor's business name from the demo page, or the sample shop's.
String _shopName() {
  final raw = (Uri.base.queryParameters['shop'] ?? '').trim();
  if (raw.isEmpty) return 'Sri Lakshmi Stores';
  return raw.length > 60 ? raw.substring(0, 60) : raw;
}
