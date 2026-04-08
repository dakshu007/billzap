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

  Customer({
    String? id, required this.name, this.phone = '', this.email = '',
    this.address = '', this.gstin = '', this.city = '', this.state = '',
    DateTime? createdAt,
  }) : id = id ?? genId(), createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'phone': phone, 'email': email,
    'address': address, 'gstin': gstin, 'city': city, 'state': state,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
    id: m['id'], name: m['name'] ?? '', phone: m['phone'] ?? '',
    email: m['email'] ?? '', address: m['address'] ?? '',
    gstin: m['gstin'] ?? '', city: m['city'] ?? '', state: m['state'] ?? '',
    createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
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
  final DateTime createdAt;

  Product({
    String? id, required this.name, this.hsnCode = '', this.unit = 'Nos',
    required this.price, this.gstRate = 18, this.isService = false,
    DateTime? createdAt,
  }) : id = id ?? genId(), createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'hsnCode': hsnCode, 'unit': unit,
    'price': price, 'gstRate': gstRate, 'isService': isService,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Product.fromMap(Map<String, dynamic> m) => Product(
    id: m['id'], name: m['name'] ?? '', hsnCode: m['hsnCode'] ?? '',
    unit: m['unit'] ?? 'Nos',
    price: (m['price'] as num?)?.toDouble() ?? 0,
    gstRate: (m['gstRate'] as num?)?.toDouble() ?? 18,
    isService: m['isService'] ?? false,
    createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
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
  }) : id = id ?? genId(), createdAt = createdAt ?? DateTime.now();

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

  Expense({
    String? id, required this.category, required this.title,
    required this.amount, required this.date, this.paymentMode = 'UPI',
    DateTime? createdAt,
  }) : id = id ?? genId(), createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id, 'category': category, 'title': title, 'amount': amount,
    'date': date.toIso8601String(), 'paymentMode': paymentMode,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
    id: m['id'], category: m['category'] ?? 'Other',
    title: m['title'] ?? '',
    amount: (m['amount'] as num?)?.toDouble() ?? 0,
    date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
    paymentMode: m['paymentMode'] ?? 'UPI',
    createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
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
