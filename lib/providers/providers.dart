// lib/providers/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/local_storage.dart';
import '../tax/countries.dart';
import '../tax/profiles.dart';
import '../tax/tax_engine.dart';
import '../tax/tax_profile.dart';
import '../design/money.dart';

final storageProvider = Provider<LocalStorage>((_) => LocalStorage.instance);

// ─── Business ─────────────────────────────────────────────────────────────
class BusinessNotifier extends Notifier<Business?> {
  late LocalStorage _db;

  @override
  Business? build() {
    _db = ref.watch(storageProvider);
    return _db.getBusiness();
  }

  Future<void> save(Business b) async {
    await _db.saveBusiness(b);
    state = b; // immediately updates all watchers including dashboard
  }

  void reload() => state = _db.getBusiness();
}

final businessProvider =
    NotifierProvider<BusinessNotifier, Business?>(BusinessNotifier.new);

// ─── Tax profile ──────────────────────────────────────────────────────────
// The single place the app asks "what are the tax rules here?".
//
// Derived from the business profile rather than stored separately, so
// there is one source of truth and no way for the two to disagree. A
// shop with no profile yet — first launch, before onboarding — gets
// India, which is what every install had before countries existed.
//
// Screens must read this instead of hardcoding GST. The whole point of
// lib/tax/ is that create_invoice_screen does not know what country it
// is in.
final taxProfileProvider = Provider<TaxProfile>((ref) {
  final biz = ref.watch(businessProvider);
  final profile = _resolve(biz);
  // Push the currency into money.dart, which renders every amount in
  // the app and cannot read a provider — it is on the hot path of every
  // row of every list. Same shape the i18n layer already uses.
  setActiveCurrency(
    symbol: profile.currencySymbol,
    grouping: profile.grouping == NumberGrouping.indian
        ? MoneyGrouping.indian
        : MoneyGrouping.western,
  );
  return profile;
});

TaxProfile _resolve(Business? biz) {
  if (biz == null) return indiaProfile;
  return resolveProfile(
    countryCode: biz.countryCode,
    countryName: countryFor(biz.countryCode)?.name,
    customTaxName: biz.customTaxName,
    customTaxRate: biz.customTaxRate,
    customCurrencySymbol: biz.customCurrencySymbol,
    customCurrencyCode:
        countryFor(biz.countryCode)?.currencyCode ?? 'USD',
  );
}

/// The engine bound to the current profile. Screens compute totals
/// through this so the arithmetic lives in one tested place.
final taxEngineProvider = Provider<TaxEngine>(
    (ref) => TaxEngine(ref.watch(taxProfileProvider)));

// ─── Invoices ─────────────────────────────────────────────────────────────
class InvoiceNotifier extends Notifier<List<Invoice>> {
  late LocalStorage _db;

  @override
  List<Invoice> build() {
    _db = ref.watch(storageProvider);
    return _db.getInvoices();
  }

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

  // Mark as paid
  Future<void> markPaid(String id) async {
    await _db.markInvoicePaid(id);
    state = _db.getInvoices();
  }

  // NEW: Mark as unpaid
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

final invoiceProvider =
    NotifierProvider<InvoiceNotifier, List<Invoice>>(InvoiceNotifier.new);

/// The invoice currently open in the preview / editor.
///
/// Riverpod 3 removed the simple value-provider, and a Notifier's `state`
/// setter is protected, so selection goes through an explicit method
/// rather than being poked from the outside.
class SelectedInvoiceNotifier extends Notifier<Invoice?> {
  @override
  Invoice? build() => null;

  void select(Invoice? invoice) => state = invoice;
  void clear() => state = null;
}

final selectedInvoiceProvider =
    NotifierProvider<SelectedInvoiceNotifier, Invoice?>(
        SelectedInvoiceNotifier.new);

// ─── Customers ────────────────────────────────────────────────────────────
class CustomerNotifier extends Notifier<List<Customer>> {
  late LocalStorage _db;

  @override
  List<Customer> build() {
    _db = ref.watch(storageProvider);
    return _db.getCustomers();
  }

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

final customerProvider =
    NotifierProvider<CustomerNotifier, List<Customer>>(CustomerNotifier.new);

// ─── Products ─────────────────────────────────────────────────────────────
class ProductNotifier extends Notifier<List<Product>> {
  late LocalStorage _db;

  @override
  List<Product> build() {
    _db = ref.watch(storageProvider);
    return _db.getProducts();
  }

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

final productProvider =
    NotifierProvider<ProductNotifier, List<Product>>(ProductNotifier.new);

// ─── Expenses ─────────────────────────────────────────────────────────────
class ExpenseNotifier extends Notifier<List<Expense>> {
  late LocalStorage _db;

  @override
  List<Expense> build() {
    _db = ref.watch(storageProvider);
    return _db.getExpenses();
  }

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

final expenseProvider =
    NotifierProvider<ExpenseNotifier, List<Expense>>(ExpenseNotifier.new);
