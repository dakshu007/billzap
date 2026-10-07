// lib/utils/csv_import.dart — products and customers from a spreadsheet.
//
// Pure Dart, no Flutter, so every rule here is tested in
// test/csv_import_test.dart.
//
// FORGIVING ON PURPOSE
//
// The file comes out of whatever the shopkeeper has: Excel on a shop
// PC, Google Sheets on a phone, an export from the old billing app.
// So:
//   • columns are found by name, in any order, under the names people
//     actually use ("Item", "Product", "MRP", "Selling price", "Mobile")
//   • comma, semicolon and tab separators all work — European Excel
//     saves CSV with semicolons because the comma is their decimal point
//   • "1,250.50", "1.250,50", "₹ 1,250" and "12,5" are all numbers
//   • a byte-order mark, quoted fields with commas and line breaks
//     inside them, and blank lines are all handled
//   • one bad row never sinks the file: it is reported with its line
//     number and the rest still import

/// Split CSV text into rows of fields.
List<List<String>> parseCsv(String text) {
  var src = text;
  if (src.startsWith('﻿')) src = src.substring(1);
  final delim = _detectDelimiter(src);
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < src.length; i++) {
    final ch = src[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < src.length && src[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(ch);
      }
      continue;
    }
    if (ch == '"') {
      inQuotes = true;
    } else if (ch == delim) {
      row.add(field.toString());
      field.clear();
    } else if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && i + 1 < src.length && src[i + 1] == '\n') i++;
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = <String>[];
    } else {
      field.write(ch);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}

/// The separator the header line uses most, outside quotes.
String _detectDelimiter(String src) {
  final end = src.indexOf('\n');
  final header = end < 0 ? src : src.substring(0, end);
  var inQuotes = false;
  final counts = {',': 0, ';': 0, '\t': 0};
  for (final ch in header.split('')) {
    if (ch == '"') inQuotes = !inQuotes;
    if (!inQuotes && counts.containsKey(ch)) counts[ch] = counts[ch]! + 1;
  }
  var best = ',';
  for (final e in counts.entries) {
    if (e.value > counts[best]!) best = e.key;
  }
  return best;
}

/// A money or quantity value as people type it. Null when there is no
/// number in it at all.
double? parseLooseNumber(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return null;
  // Keep digits, separators and a leading minus; drop currency symbols,
  // spaces, "Rs." and the like.
  final negative = s.startsWith('-') || s.startsWith('(');
  s = s.replaceAll(RegExp(r'[^0-9.,]'), '');
  // "Rs. 99" leaves ".99"; a separator at either end is never a decimal.
  s = s.replaceAll(RegExp(r'^[.,]+|[.,]+$'), '');
  if (s.isEmpty) return null;
  final lastComma = s.lastIndexOf(',');
  final lastDot = s.lastIndexOf('.');
  if (lastComma >= 0 && lastDot >= 0) {
    // Both present: whichever comes last is the decimal point.
    if (lastComma > lastDot) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '');
    }
  } else if (lastComma >= 0) {
    // Only commas. "1,250" and "12,50,000" are grouping; "12,5" and
    // "12,50" are a decimal comma.
    final after = s.length - lastComma - 1;
    final groups = s.split(',');
    final isGrouping = after == 3 ||
        (groups.length > 2 && groups.skip(1).every((g) => g.length == 2 || g.length == 3));
    s = isGrouping ? s.replaceAll(',', '') : s.replaceAll(',', '.');
  }
  // More than one dot left means dots were grouping ("1.250.000").
  if ('.'.allMatches(s).length > 1) s = s.replaceAll('.', '');
  final v = double.tryParse(s);
  if (v == null) return null;
  return negative ? -v : v;
}

String _norm(String h) => h.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// Which column holds what, by header name. Unknown headers are ignored.
Map<String, int> _mapColumns(List<String> header, Map<String, List<String>> aliases) {
  final out = <String, int>{};
  for (var i = 0; i < header.length; i++) {
    final h = _norm(header[i]);
    if (h.isEmpty) continue;
    for (final e in aliases.entries) {
      if (out.containsKey(e.key)) continue;
      if (e.value.contains(h)) {
        out[e.key] = i;
        break;
      }
    }
  }
  return out;
}

const productColumns = <String, List<String>>{
  'name': ['name', 'item', 'itemname', 'product', 'productname', 'description', 'particulars', 'goods'],
  'price': ['price', 'rate', 'sellingprice', 'saleprice', 'sellprice', 'mrp', 'unitprice', 'amount'],
  'cost': ['cost', 'costprice', 'purchaseprice', 'buyingprice', 'buyprice'],
  'tax': ['tax', 'taxrate', 'gst', 'gstrate', 'gstpercent', 'vat', 'vatrate', 'taxpercent'],
  'unit': ['unit', 'uom', 'units'],
  'code': ['hsn', 'hsncode', 'sac', 'hsnsac', 'code', 'itemcode', 'sku', 'barcode'],
  'stock': ['stock', 'qty', 'quantity', 'stockqty', 'onhand', 'opening', 'openingstock'],
  'low': ['lowstock', 'lowstockat', 'reorder', 'reorderlevel', 'minstock', 'alertat'],
};

const customerColumns = <String, List<String>>{
  'name': ['name', 'customer', 'customername', 'party', 'partyname', 'client', 'clientname', 'fullname'],
  'phone': ['phone', 'mobile', 'mobileno', 'phoneno', 'phonenumber', 'mobilenumber', 'contact', 'whatsapp', 'tel'],
  'email': ['email', 'emailid', 'mail', 'emailaddress'],
  'address': ['address', 'address1', 'street', 'billingaddress'],
  'city': ['city', 'town', 'place'],
  'state': ['state', 'region', 'province', 'county'],
  'taxid': ['gstin', 'gst', 'gstno', 'taxid', 'vat', 'vatno', 'vatnumber', 'trn', 'ein', 'tin', 'taxnumber'],
};

/// One problem row, with the line it is on in the file (1-based,
/// counting the header) so the shopkeeper can find it.
class CsvRowError {
  final int line;
  final String reason; // a translation key: csv.err_no_name, csv.err_no_price
  const CsvRowError(this.line, this.reason);
}

class ProductRow {
  final String name;
  final double price;
  final double? cost;
  final double? taxRate;
  final String unit;
  final String code;
  final double? stock;
  final double? lowStockAt;
  const ProductRow({
    required this.name,
    required this.price,
    this.cost,
    this.taxRate,
    this.unit = '',
    this.code = '',
    this.stock,
    this.lowStockAt,
  });
}

class CustomerRow {
  final String name, phone, email, address, city, state, taxId;
  const CustomerRow({
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.taxId = '',
  });
}

class CsvParse<T> {
  final List<T> rows;
  final List<CsvRowError> errors;
  /// False when the header has no column the importer recognises as the
  /// name — almost always the wrong file, or a file with no header row.
  final bool headerFound;
  const CsvParse(this.rows, this.errors, {this.headerFound = true});
}

String _cell(List<String> r, int? i) =>
    (i == null || i >= r.length) ? '' : r[i].trim();

bool _blank(List<String> r) => r.every((c) => c.trim().isEmpty);

CsvParse<ProductRow> parseProductsCsv(String text) {
  final rows = parseCsv(text);
  if (rows.isEmpty) return const CsvParse([], [], headerFound: false);
  final cols = _mapColumns(rows.first, productColumns);
  if (!cols.containsKey('name')) return const CsvParse([], [], headerFound: false);
  final out = <ProductRow>[];
  final errors = <CsvRowError>[];
  for (var i = 1; i < rows.length; i++) {
    final r = rows[i];
    if (_blank(r)) continue;
    final name = _cell(r, cols['name']);
    if (name.isEmpty) {
      errors.add(CsvRowError(i + 1, 'csv.err_no_name'));
      continue;
    }
    final price = parseLooseNumber(_cell(r, cols['price']));
    if (price == null || price < 0) {
      errors.add(CsvRowError(i + 1, 'csv.err_no_price'));
      continue;
    }
    final tax = parseLooseNumber(_cell(r, cols['tax']));
    out.add(ProductRow(
      name: name,
      price: price,
      cost: parseLooseNumber(_cell(r, cols['cost'])),
      taxRate: (tax != null && tax >= 0 && tax <= 100) ? tax : null,
      unit: _cell(r, cols['unit']),
      code: _cell(r, cols['code']),
      stock: parseLooseNumber(_cell(r, cols['stock'])),
      lowStockAt: parseLooseNumber(_cell(r, cols['low'])),
    ));
  }
  return CsvParse(out, errors);
}

CsvParse<CustomerRow> parseCustomersCsv(String text) {
  final rows = parseCsv(text);
  if (rows.isEmpty) return const CsvParse([], [], headerFound: false);
  final cols = _mapColumns(rows.first, customerColumns);
  if (!cols.containsKey('name')) return const CsvParse([], [], headerFound: false);
  final out = <CustomerRow>[];
  final errors = <CsvRowError>[];
  for (var i = 1; i < rows.length; i++) {
    final r = rows[i];
    if (_blank(r)) continue;
    final name = _cell(r, cols['name']);
    if (name.isEmpty) {
      errors.add(CsvRowError(i + 1, 'csv.err_no_name'));
      continue;
    }
    out.add(CustomerRow(
      name: name,
      phone: _cell(r, cols['phone']),
      email: _cell(r, cols['email']),
      address: _cell(r, cols['address']),
      city: _cell(r, cols['city']),
      state: _cell(r, cols['state']),
      taxId: _cell(r, cols['taxid']).toUpperCase(),
    ));
  }
  return CsvParse(out, errors);
}

/// Name key for "is this the same product / customer": case, spacing
/// and punctuation do not make a different item.
String sameNameKey(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9À-￿]'), '');

/// Digits of a phone number, last ten — enough to tell two customers
/// apart while ignoring "+91", spaces and dashes.
String samePhoneKey(String s) {
  final d = s.replaceAll(RegExp(r'[^0-9]'), '');
  return d.length > 10 ? d.substring(d.length - 10) : d;
}
