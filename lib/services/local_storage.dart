// lib/services/local_storage.dart — All persistence via Hive, zero Firebase

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class LocalStorage {
  static const _kBusiness  = 'business';
  static const _kInvoices  = 'invoices';
  static const _kCustomers = 'customers';
  static const _kProducts  = 'products';
  static const _kExpenses  = 'expenses';

  static final LocalStorage instance = LocalStorage._();
  LocalStorage._();

  late Box _box;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();
    _box = await Hive.openBox('billzap_v1');
    _ready = true;
  }

  // ── Business ──────────────────────────────────────────────────────────

  Business? getBusiness() {
    try {
      final raw = _box.get(_kBusiness);
      if (raw == null) return null;
      return Business.fromMap(jsonDecode(raw as String) as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  Future<void> saveBusiness(Business b) async {
    await _box.put(_kBusiness, jsonEncode(b.toMap()));
  }

  // ── Invoices ──────────────────────────────────────────────────────────

  List<Invoice> getInvoices() {
    try {
      final raw = _box.get(_kInvoices);
      if (raw == null) return [];
      final list = jsonDecode(raw as String) as List;
      return list
          .map((m) => Invoice.fromMap(Map<String, dynamic>.from(m)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) { return []; }
  }

  Future<void> saveInvoice(Invoice inv) async {
    final list = getInvoices();
    final idx = list.indexWhere((i) => i.id == inv.id);
    if (idx >= 0) list[idx] = inv; else list.insert(0, inv);
    await _box.put(_kInvoices, jsonEncode(list.map((i) => i.toMap()).toList()));
  }

  Future<void> deleteInvoice(String id) async {
    final list = getInvoices()..removeWhere((i) => i.id == id);
    await _box.put(_kInvoices, jsonEncode(list.map((i) => i.toMap()).toList()));
  }

  Future<void> markInvoicePaid(String id) async {
    final list = getInvoices();
    for (final inv in list) {
      if (inv.id == id) {
        inv.status = InvoiceStatus.paid;
        inv.paidAt = DateTime.now();
        break;
      }
    }
    await _box.put(_kInvoices, jsonEncode(list.map((i) => i.toMap()).toList()));
  }

  // ✅ NEW: Mark as unpaid
  Future<void> markInvoiceUnpaid(String id) async {
    final list = getInvoices();
    for (final inv in list) {
      if (inv.id == id) {
        inv.status = InvoiceStatus.sent;
        inv.paidAt = null;
        break;
      }
    }
    await _box.put(_kInvoices, jsonEncode(list.map((i) => i.toMap()).toList()));
  }

  // ── Customers ────────────────────────────────────────────────────────

  List<Customer> getCustomers() {
    try {
      final raw = _box.get(_kCustomers);
      if (raw == null) return [];
      final list = jsonDecode(raw as String) as List;
      return list
          .map((m) => Customer.fromMap(Map<String, dynamic>.from(m)))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (_) { return []; }
  }

  Future<void> saveCustomer(Customer c) async {
    final list = getCustomers();
    final idx = list.indexWhere((x) => x.id == c.id);
    if (idx >= 0) list[idx] = c; else list.add(c);
    await _box.put(_kCustomers, jsonEncode(list.map((x) => x.toMap()).toList()));
  }

  Future<void> deleteCustomer(String id) async {
    final list = getCustomers()..removeWhere((c) => c.id == id);
    await _box.put(_kCustomers, jsonEncode(list.map((c) => c.toMap()).toList()));
  }

  // ── Products ──────────────────────────────────────────────────────────

  List<Product> getProducts() {
    try {
      final raw = _box.get(_kProducts);
      if (raw == null) return [];
      final list = jsonDecode(raw as String) as List;
      return list
          .map((m) => Product.fromMap(Map<String, dynamic>.from(m)))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (_) { return []; }
  }

  Future<void> saveProduct(Product p) async {
    final list = getProducts();
    final idx = list.indexWhere((x) => x.id == p.id);
    if (idx >= 0) list[idx] = p; else list.add(p);
    await _box.put(_kProducts, jsonEncode(list.map((x) => x.toMap()).toList()));
  }

  Future<void> deleteProduct(String id) async {
    final list = getProducts()..removeWhere((p) => p.id == id);
    await _box.put(_kProducts, jsonEncode(list.map((p) => p.toMap()).toList()));
  }

  // ── Expenses ──────────────────────────────────────────────────────────

  List<Expense> getExpenses() {
    try {
      final raw = _box.get(_kExpenses);
      if (raw == null) return [];
      final list = jsonDecode(raw as String) as List;
      return list
          .map((m) => Expense.fromMap(Map<String, dynamic>.from(m)))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (_) { return []; }
  }

  Future<void> saveExpense(Expense e) async {
    final list = getExpenses();
    final idx = list.indexWhere((x) => x.id == e.id);
    if (idx >= 0) list[idx] = e; else list.insert(0, e);
    await _box.put(_kExpenses, jsonEncode(list.map((x) => x.toMap()).toList()));
  }

  Future<void> deleteExpense(String id) async {
    final list = getExpenses()..removeWhere((e) => e.id == id);
    await _box.put(_kExpenses, jsonEncode(list.map((e) => e.toMap()).toList()));
  }

  // ── Invoice number ────────────────────────────────────────────────────

  String nextInvoiceNumber() {
    final biz = getBusiness();
    final prefix = biz?.invoicePrefix ?? 'INV-';
    final num = biz?.nextInvoiceNumber ?? 1001;
    if (biz != null) {
      biz.nextInvoiceNumber = num + 1;
      saveBusiness(biz);
    }
    return '$prefix$num';
  }
}
