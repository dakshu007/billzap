// lib/models/models.dart — Complete data models, zero Firebase

import 'package:uuid/uuid.dart';

const _uuid = Uuid();
String genId() => _uuid.v4();

// ─── ENUMS ────────────────────────────────────────────────────────────────

enum InvoiceStatus { draft, sent, pending, paid, cancelled }
enum GstType { cgstSgst, igst }

// ─── BUSINESS ─────────────────────────────────────────────────────────────

class Business {
  final String id;
  String name;
  String gstin;
  String phone;
  String email;
  String address;
  String city;
  String state;
  String stateCode;
  String pincode;
  String bankName;
  String accountNumber;
  String ifscCode;
  String upiId;
  String invoicePrefix;
  int nextInvoiceNumber;
  String defaultTerms;

  Business({
    String? id,
    this.name = '',
    this.gstin = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.city = '',
    this.state = 'Tamil Nadu',
    this.stateCode = '33',
    this.pincode = '',
    this.bankName = '',
    this.accountNumber = '',
    this.ifscCode = '',
    this.upiId = '',
    this.invoicePrefix = 'INV-',
    this.nextInvoiceNumber = 1001,
    this.defaultTerms = 'Payment due within 30 days.',
  }) : id = id ?? genId();

  Business copyWith({
    String? name, String? gstin, String? phone, String? email,
    String? address, String? city, String? state, String? stateCode,
    String? pincode, String? bankName, String? accountNumber,
    String? ifscCode, String? upiId, String? invoicePrefix,
    int? nextInvoiceNumber, String? defaultTerms,
  }) => Business(
    id: id,
    name: name ?? this.name, gstin: gstin ?? this.gstin,
    phone: phone ?? this.phone, email: email ?? this.email,
    address: address ?? this.address, city: city ?? this.city,
    state: state ?? this.state, stateCode: stateCode ?? this.stateCode,
    pincode: pincode ?? this.pincode, bankName: bankName ?? this.bankName,
    accountNumber: accountNumber ?? this.accountNumber,
    ifscCode: ifscCode ?? this.ifscCode, upiId: upiId ?? this.upiId,
    invoicePrefix: invoicePrefix ?? this.invoicePrefix,
    nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
    defaultTerms: defaultTerms ?? this.defaultTerms,
  );

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'gstin': gstin, 'phone': phone, 'email': email,
    'address': address, 'city': city, 'state': state, 'stateCode': stateCode,
    'pincode': pincode, 'bankName': bankName, 'accountNumber': accountNumber,
    'ifscCode': ifscCode, 'upiId': upiId, 'invoicePrefix': invoicePrefix,
    'nextInvoiceNumber': nextInvoiceNumber, 'defaultTerms': defaultTerms,
  };

  factory Business.fromMap(Map<String, dynamic> m) => Business(
    id: m['id'], name: m['name'] ?? '', gstin: m['gstin'] ?? '',
    phone: m['phone'] ?? '', email: m['email'] ?? '',
    address: m['address'] ?? '', city: m['city'] ?? '',
    state: m['state'] ?? 'Tamil Nadu', stateCode: m['stateCode'] ?? '33',
    pincode: m['pincode'] ?? '', bankName: m['bankName'] ?? '',
    accountNumber: m['accountNumber'] ?? '', ifscCode: m['ifscCode'] ?? '',
    upiId: m['upiId'] ?? '', invoicePrefix: m['invoicePrefix'] ?? 'INV-',
    nextInvoiceNumber: (m['nextInvoiceNumber'] as int?) ?? 1001,
    defaultTerms: m['defaultTerms'] ?? 'Payment due within 30 days.',
  );
}

// ─── CUSTOMER ─────────────────────────────────────────────────────────────

class Customer {
  final String id;
  String name;
  String phone;
  String email;
  String address;
  String gstin;
  String city;
  String state;
  final DateTime createdAt;
  // Sync foundation — stamped on every save. Combined with the UUID `id`,
  // makes last-write-wins sync trivial later.
  DateTime updatedAt;

  Customer({
    String? id, required this.name, this.phone = '', this.email = '',
    this.address = '', this.gstin = '', this.city = '', this.state = '',
    DateTime? createdAt, DateTime? updatedAt,
  })  : id = id ?? genId(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  void touch() => updatedAt = DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'phone': phone, 'email': email,
    'address': address, 'gstin': gstin, 'city': city, 'state': state,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
    id: m['id'], name: m['name'] ?? '', phone: m['phone'] ?? '',
    email: m['email'] ?? '', address: m['address'] ?? '',
    gstin: m['gstin'] ?? '', city: m['city'] ?? '', state: m['state'] ?? '',
    createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(m['updatedAt'] ?? '') ??
        DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
  );
}

// ─── PRODUCT ──────────────────────────────────────────────────────────────

class Product {
  final String id;
  String name;
  String hsnCode;
  String unit;
  double price;
  double gstRate;
  bool isService;
  // Round-5 additions ───────────────────────────────────────
  // `cost`         — buying price; used to derive profit margin.
  // `stock`        — current on-hand quantity. Auto-decremented when an
  //                  invoice is saved (best-effort name match). Set to
  //                  -1 to opt-out of stock tracking for this item
  //                  (e.g. services that don't have inventory).
  // `lowStockAt`   — threshold for "low stock" alert; 0 disables.
  double cost;
  double stock;
  double lowStockAt;
  // ─────────────────────────────────────────────────────────
  final DateTime createdAt;
  // Sync foundation — bumped on every save (see ProductNotifier).
  DateTime updatedAt;

  Product({
    String? id, required this.name, this.hsnCode = '', this.unit = 'Nos',
    required this.price, this.gstRate = 18, this.isService = false,
    this.cost = 0, this.stock = -1, this.lowStockAt = 0,
    DateTime? createdAt, DateTime? updatedAt,
  })  : id = id ?? genId(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  void touch() => updatedAt = DateTime.now();

  /// % profit margin on the sell price. Returns null when cost is 0/empty
  /// so callers can render "—" instead of a misleading 100%.
  double? get marginPercent {
    if (cost <= 0 || price <= 0) return null;
    return ((price - cost) / price) * 100;
  }

  /// True if we're actively tracking stock for this product AND it has
  /// hit (or dipped below) the configured threshold.
  bool get isLowStock =>
      stock >= 0 && lowStockAt > 0 && stock <= lowStockAt;

  /// True if stock tracking is on and we're sold out.
  bool get isOutOfStock => stock == 0;

  /// Whether stock tracking is enabled for this product.
  bool get tracksStock => stock >= 0;

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'hsnCode': hsnCode, 'unit': unit,
    'price': price, 'gstRate': gstRate, 'isService': isService,
    'cost': cost, 'stock': stock, 'lowStockAt': lowStockAt,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Product.fromMap(Map<String, dynamic> m) => Product(
    id: m['id'], name: m['name'] ?? '', hsnCode: m['hsnCode'] ?? '',
    unit: m['unit'] ?? 'Nos',
    price: (m['price'] as num?)?.toDouble() ?? 0,
    gstRate: (m['gstRate'] as num?)?.toDouble() ?? 18,
    isService: m['isService'] ?? false,
    // -1 default for `stock` preserves backwards-compat: products created
    // before round 5 won't accidentally read as "0 stock = out of stock".
    cost: (m['cost'] as num?)?.toDouble() ?? 0,
    stock: (m['stock'] as num?)?.toDouble() ?? -1,
    lowStockAt: (m['lowStockAt'] as num?)?.toDouble() ?? 0,
    createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(m['updatedAt'] ?? '') ??
        DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
  );
}

// ─── INVOICE ITEM ─────────────────────────────────────────────────────────

class InvoiceItem {
  String name;
  String hsnCode;
  String unit;
  double quantity;
  double rate;
  double gstRate;
  bool applyGst;

  InvoiceItem({
    required this.name, this.hsnCode = '', this.unit = 'Nos',
    required this.quantity, required this.rate,
    this.gstRate = 18, this.applyGst = true,
  });

  double get taxable => quantity * rate;
  double get gstAmount => applyGst ? taxable * gstRate / 100 : 0;
  double get total => taxable + gstAmount;

  Map<String, dynamic> toMap() => {
    'name': name, 'hsnCode': hsnCode, 'unit': unit,
    'quantity': quantity, 'rate': rate, 'gstRate': gstRate, 'applyGst': applyGst,
  };

  factory InvoiceItem.fromMap(Map<String, dynamic> m) => InvoiceItem(
    name: m['name'] ?? '', hsnCode: m['hsnCode'] ?? '', unit: m['unit'] ?? 'Nos',
    quantity: (m['quantity'] as num?)?.toDouble() ?? 1,
    rate: (m['rate'] as num?)?.toDouble() ?? 0,
    gstRate: (m['gstRate'] as num?)?.toDouble() ?? 18,
    applyGst: m['applyGst'] ?? true,
  );
}

// ─── INVOICE ──────────────────────────────────────────────────────────────

class Invoice {
  final String id;
  String invoiceNumber;
  String customerId;
  String customerName;
  String customerPhone;
  String customerGstin;
  String customerAddress;
  DateTime invoiceDate;
  DateTime dueDate;
  List<InvoiceItem> lineItems;
  GstType gstType;
  double shippingCharge;
  double flatDiscount;
  String notes;
  String terms;
  InvoiceStatus status;
  final DateTime createdAt;
  DateTime? paidAt;
  String placeOfSupply;
  // Sync foundation — refreshed on every save / status change.
  DateTime updatedAt;

  Invoice({
    String? id, required this.invoiceNumber, this.customerId = '',
    required this.customerName, this.customerPhone = '',
    this.customerGstin = '', this.customerAddress = '',
    required this.invoiceDate, required this.dueDate,
    required this.lineItems, this.gstType = GstType.cgstSgst,
    this.shippingCharge = 0, this.flatDiscount = 0,
    this.notes = '', this.terms = 'Payment due within 30 days.',
    this.status = InvoiceStatus.sent, DateTime? createdAt,
    this.paidAt, this.placeOfSupply = 'Tamil Nadu (33)',
    DateTime? updatedAt,
  })  : id = id ?? genId(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  void touch() => updatedAt = DateTime.now();

  double get subtotal => lineItems.fold(0, (s, i) => s + i.taxable);
  double get totalTax => lineItems.fold(0, (s, i) => s + i.gstAmount);
  double get totalCgst => gstType == GstType.cgstSgst ? totalTax / 2 : 0;
  double get totalSgst => gstType == GstType.cgstSgst ? totalTax / 2 : 0;
  double get totalIgst => gstType == GstType.igst ? totalTax : 0;
  double get grandTotal => subtotal + totalTax + shippingCharge - flatDiscount;
  bool get isOverdue =>
      status != InvoiceStatus.paid &&
      status != InvoiceStatus.cancelled &&
      dueDate.isBefore(DateTime.now());
  double get gstRateForDisplay =>
      lineItems.isNotEmpty ? lineItems.first.gstRate : 18;

  Map<String, dynamic> toMap() => {
    'id': id, 'invoiceNumber': invoiceNumber, 'customerId': customerId,
    'customerName': customerName, 'customerPhone': customerPhone,
    'customerGstin': customerGstin, 'customerAddress': customerAddress,
    'invoiceDate': invoiceDate.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'lineItems': lineItems.map((i) => i.toMap()).toList(),
    'gstType': gstType.name, 'shippingCharge': shippingCharge,
    'flatDiscount': flatDiscount, 'notes': notes, 'terms': terms,
    'status': status.name, 'createdAt': createdAt.toIso8601String(),
    'paidAt': paidAt?.toIso8601String(), 'placeOfSupply': placeOfSupply,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Invoice.fromMap(Map<String, dynamic> m) => Invoice(
    id: m['id'], invoiceNumber: m['invoiceNumber'] ?? '',
    customerId: m['customerId'] ?? '',
    customerName: m['customerName'] ?? '',
    customerPhone: m['customerPhone'] ?? '',
    customerGstin: m['customerGstin'] ?? '',
    customerAddress: m['customerAddress'] ?? '',
    invoiceDate: DateTime.tryParse(m['invoiceDate'] ?? '') ?? DateTime.now(),
    dueDate: DateTime.tryParse(m['dueDate'] ?? '') ??
        DateTime.now().add(const Duration(days: 30)),
    lineItems: ((m['lineItems'] as List?) ?? [])
        .map((i) => InvoiceItem.fromMap(Map<String, dynamic>.from(i)))
        .toList(),
    gstType: m['gstType'] == 'igst' ? GstType.igst : GstType.cgstSgst,
    shippingCharge: (m['shippingCharge'] as num?)?.toDouble() ?? 0,
    flatDiscount: (m['flatDiscount'] as num?)?.toDouble() ?? 0,
    notes: m['notes'] ?? '', terms: m['terms'] ?? '',
    status: InvoiceStatus.values.firstWhere(
        (e) => e.name == m['status'], orElse: () => InvoiceStatus.draft),
    createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
    paidAt: m['paidAt'] != null ? DateTime.tryParse(m['paidAt']) : null,
    placeOfSupply: m['placeOfSupply'] ?? 'Tamil Nadu (33)',
    updatedAt: DateTime.tryParse(m['updatedAt'] ?? '') ??
        DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
  );
}

// ─── EXPENSE ──────────────────────────────────────────────────────────────

class Expense {
  final String id;
  String category;
  String title;
  double amount;
  DateTime date;
  String paymentMode;
  final DateTime createdAt;
  // Sync foundation.
  DateTime updatedAt;

  Expense({
    String? id, required this.category, required this.title,
    required this.amount, required this.date, this.paymentMode = 'UPI',
    DateTime? createdAt, DateTime? updatedAt,
  })  : id = id ?? genId(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  void touch() => updatedAt = DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id, 'category': category, 'title': title, 'amount': amount,
    'date': date.toIso8601String(), 'paymentMode': paymentMode,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
    id: m['id'], category: m['category'] ?? 'Other',
    title: m['title'] ?? '',
    amount: (m['amount'] as num?)?.toDouble() ?? 0,
    date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
    paymentMode: m['paymentMode'] ?? 'UPI',
    createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(m['updatedAt'] ?? '') ??
        DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
  );
}

// ─── CONSTANTS ────────────────────────────────────────────────────────────

String formatCurrency(double amount) {
  if (amount == 0) return '\u20b90';
  final isNeg = amount < 0;
  final abs = amount.abs();
  final parts = abs.toStringAsFixed(2).split('.');
  String integer = parts[0];
  final decimal = parts[1];
  if (integer.length > 3) {
    final last3 = integer.substring(integer.length - 3);
    final rest = integer.substring(0, integer.length - 3);
    final groups = <String>[];
    for (var i = rest.length; i > 0; i -= 2) {
      groups.insert(0, rest.substring(i < 2 ? 0 : i - 2, i));
    }
    integer = '${groups.join(',')},$last3';
  }
  return '${isNeg ? '-' : ''}\u20b9$integer.$decimal';
}

const kStates = [
  'Andhra Pradesh (37)', 'Assam (18)', 'Bihar (10)', 'Chandigarh (04)',
  'Delhi (07)', 'Gujarat (24)', 'Haryana (06)', 'Himachal Pradesh (02)',
  'Jharkhand (20)', 'Karnataka (29)', 'Kerala (32)',
  'Madhya Pradesh (23)', 'Maharashtra (27)', 'Odisha (21)',
  'Punjab (03)', 'Rajasthan (08)', 'Tamil Nadu (33)',
  'Telangana (36)', 'Uttar Pradesh (09)', 'West Bengal (19)',
];

const kStateMap = {
  'Andhra Pradesh': '37', 'Assam': '18', 'Bihar': '10',
  'Chandigarh': '04', 'Delhi': '07', 'Gujarat': '24',
  'Haryana': '06', 'Himachal Pradesh': '02', 'Jharkhand': '20',
  'Karnataka': '29', 'Kerala': '32', 'Madhya Pradesh': '23',
  'Maharashtra': '27', 'Odisha': '21', 'Punjab': '03',
  'Rajasthan': '08', 'Tamil Nadu': '33', 'Telangana': '36',
  'Uttar Pradesh': '09', 'West Bengal': '19',
};

const kExpenseCategories = [
  'Rent', 'Salary', 'Purchase', 'Utilities', 'Transport',
  'Marketing', 'Office', 'Food', 'Travel', 'Other',
];

const kUnits = [
  'Nos', 'Pcs', 'Kg', 'Gram', 'Meter', 'Ltr',
  'Box', 'Set', 'Hour', 'Day', 'Month', 'Year',
];

const kGstRates = [
  (rate: 0.0,   label: '0% — Exempt (fresh food, milk, education)'),
  (rate: 0.25,  label: '0.25% — Rough precious stones'),
  (rate: 5.0,   label: '5% — Daily essentials, processed food'),
  (rate: 12.0,  label: '12% — Computers, processed food'),
  (rate: 18.0,  label: '18% — Standard (electronics, telecom, restaurants)'),
  (rate: 28.0,  label: '28% — Luxury (cars, AC, high-end products)'),
  (rate: 40.0,  label: '40% — Sin/Luxury (tobacco, aerated beverages)'),
];
