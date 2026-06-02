// lib/providers/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/local_storage.dart';

final storageProvider = Provider<LocalStorage>((_) => LocalStorage.instance);

// ─── Business ─────────────────────────────────────────────────────────────
class BusinessNotifier extends StateNotifier<Business?> {
  final LocalStorage _db;
  BusinessNotifier(this._db) : super(_db.getBusiness());

  Future<void> save(Business b) async {
    await _db.saveBusiness(b);
    state = b; // ✅ immediately updates all watchers including dashboard
  }

  void reload() => state = _db.getBusiness();
}

final businessProvider = StateNotifierProvider<BusinessNotifier, Business?>(
  (ref) => BusinessNotifier(ref.watch(storageProvider)));

// ─── Invoices ─────────────────────────────────────────────────────────────
class InvoiceNotifier extends StateNotifier<List<Invoice>> {
  final LocalStorage _db;
  InvoiceNotifier(this._db) : super(_db.getInvoices());

  Future<void> add(Invoice inv) async {
    inv.touch(); // sync foundation: bump updatedAt
    await _db.saveInvoice(inv);
    // Auto-decrement stock for each line item that matches a tracked
    // product by name (case-insensitive). Best-effort — if the name
    // doesn't match exactly, we just skip (no error). Products with
    // `stock == -1` (tracking opted-out / default for legacy products)
    // are also skipped.
    _decrementStockForInvoice(inv);
    state = _db.getInvoices();
  }

  Future<void> update(Invoice inv) async {
    inv.touch();
    await _db.saveInvoice(inv);
    state = _db.getInvoices();
  }

  Future<void> delete(String id) async {
    await _db.deleteInvoice(id);
    state = _db.getInvoices();
  }

  // ✅ Mark as paid
  Future<void> markPaid(String id) async {
    await _db.markInvoicePaid(id);
    state = _db.getInvoices();
  }

  // ✅ NEW: Mark as unpaid
  Future<void> markUnpaid(String id) async {
    await _db.markInvoiceUnpaid(id);
    state = _db.getInvoices();
  }

  void reload() => state = _db.getInvoices();

  /// Walks the invoice's line items and decrements `stock` on any
  /// matching tracked product. Called only on `add()` so editing a saved
  /// invoice doesn't double-deduct.
  void _decrementStockForInvoice(Invoice inv) {
    final products = _db.getProducts();
    for (final li in inv.lineItems) {
      final key = li.name.trim().toLowerCase();
      if (key.isEmpty) continue;
      final idx = products.indexWhere(
          (p) => p.name.trim().toLowerCase() == key);
      if (idx < 0) continue;
      final p = products[idx];
      if (!p.tracksStock) continue;
      // Allow stock to go negative — gives shopkeepers a chance to
      // notice an oversell without blocking the invoice save.
      p.stock = p.stock - li.quantity;
      p.touch();
      _db.saveProduct(p);
    }
  }
}

final invoiceProvider = StateNotifierProvider<InvoiceNotifier, List<Invoice>>(
  (ref) => InvoiceNotifier(ref.watch(storageProvider)));

final selectedInvoiceProvider = StateProvider<Invoice?>((ref) => null);

// ─── Customers ────────────────────────────────────────────────────────────
class CustomerNotifier extends StateNotifier<List<Customer>> {
  final LocalStorage _db;
  CustomerNotifier(this._db) : super(_db.getCustomers());

  Future<void> add(Customer c) async {
    c.touch();
    await _db.saveCustomer(c);
    state = _db.getCustomers();
  }

  Future<void> delete(String id) async {
    await _db.deleteCustomer(id);
    state = _db.getCustomers();
  }

  void reload() => state = _db.getCustomers();
}

final customerProvider = StateNotifierProvider<CustomerNotifier, List<Customer>>(
  (ref) => CustomerNotifier(ref.watch(storageProvider)));

// ─── Products ─────────────────────────────────────────────────────────────
class ProductNotifier extends StateNotifier<List<Product>> {
  final LocalStorage _db;
  ProductNotifier(this._db) : super(_db.getProducts());

  Future<void> add(Product p) async {
    p.touch();
    await _db.saveProduct(p);
    state = _db.getProducts();
  }

  /// Upsert — used for editing cost / stock / threshold after creation.
  /// (saveProduct already does an upsert, so this is a semantic alias.)
  Future<void> update(Product p) async {
    p.touch();
    await _db.saveProduct(p);
    state = _db.getProducts();
  }

  /// Manual stock adjustment helper (e.g. "received 20 more units" or
  /// "wrote off 3 damaged units"). `delta` may be negative.
  Future<void> adjustStock(String id, double delta) async {
    final list = _db.getProducts();
    final i = list.indexWhere((p) => p.id == id);
    if (i < 0) return;
    final p = list[i];
    if (!p.tracksStock) return;
    p.stock = p.stock + delta;
    p.touch();
    await _db.saveProduct(p);
    state = _db.getProducts();
  }

  Future<void> delete(String id) async {
    await _db.deleteProduct(id);
    state = _db.getProducts();
  }

  void reload() => state = _db.getProducts();
}

final productProvider = StateNotifierProvider<ProductNotifier, List<Product>>(
  (ref) => ProductNotifier(ref.watch(storageProvider)));

// ─── Expenses ─────────────────────────────────────────────────────────────
class ExpenseNotifier extends StateNotifier<List<Expense>> {
  final LocalStorage _db;
  ExpenseNotifier(this._db) : super(_db.getExpenses());

  Future<void> add(Expense e) async {
    e.touch();
    await _db.saveExpense(e);
    state = _db.getExpenses();
  }

  Future<void> delete(String id) async {
    await _db.deleteExpense(id);
    state = _db.getExpenses();
  }

  void reload() => state = _db.getExpenses();
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, List<Expense>>(
  (ref) => ExpenseNotifier(ref.watch(storageProvider)));
