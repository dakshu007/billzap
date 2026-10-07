// test/csv_import_test.dart — reading the files shopkeepers actually have.

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/utils/csv_import.dart';

void main() {
  group('parseCsv', () {
    test('quotes, embedded commas and line breaks, CRLF, BOM', () {
      final rows = parseCsv(
          '﻿Name,Price\r\n"Rice, basmati 5kg",450\r\n"Note ""A""\nline2",12\r\n');
      expect(rows[0], ['Name', 'Price']);
      expect(rows[1], ['Rice, basmati 5kg', '450']);
      expect(rows[2], ['Note "A"\nline2', '12']);
    });

    test('semicolon and tab files, as European Excel and Sheets save them',
        () {
      expect(parseCsv('Name;Price\nTea;12,50')[1], ['Tea', '12,50']);
      expect(parseCsv('Name\tPrice\nTea\t12')[1], ['Tea', '12']);
    });
  });

  group('parseLooseNumber', () {
    final cases = <String, double?>{
      '450': 450,
      '1,250': 1250,
      '1,250.50': 1250.5,
      '1.250,50': 1250.5,
      '12,50,000': 1250000,
      '12,5': 12.5,
      '₹ 1,200': 1200,
      'Rs. 99': 99,
      '\$4.99': 4.99,
      '1.250.000': 1250000,
      '': null,
      'free': null,
    };
    cases.forEach((input, want) {
      test('"$input" → $want', () => expect(parseLooseNumber(input), want));
    });
  });

  group('products', () {
    test('columns found by name, in any order, under common names', () {
      final r = parseProductsCsv(
          'MRP,Item Name,GST %,UOM,HSN Code,Purchase Price,Qty\n'
          '48,Sugar 1kg,5,Kg,1701,42,20\n');
      expect(r.headerFound, isTrue);
      final p = r.rows.single;
      expect(p.name, 'Sugar 1kg');
      expect(p.price, 48);
      expect(p.taxRate, 5);
      expect(p.unit, 'Kg');
      expect(p.code, '1701');
      expect(p.cost, 42);
      expect(p.stock, 20);
    });

    test('a bad row is reported with its line and the rest still import',
        () {
      final r = parseProductsCsv('Name,Price\nTea,10\n,5\nCoffee,\nMilk,30\n');
      expect(r.rows.map((p) => p.name), ['Tea', 'Milk']);
      expect(r.errors.map((e) => e.line), [3, 4]);
      expect(r.errors.map((e) => e.reason),
          ['csv.err_no_name', 'csv.err_no_price']);
    });

    test('blank lines are ignored, optional columns may be empty', () {
      final r = parseProductsCsv('Name,Price,Tax\n\nTea,10,\n\n');
      expect(r.rows.single.taxRate, isNull);
      expect(r.errors, isEmpty);
    });

    test('no name column means the wrong file, not a row error', () {
      expect(parseProductsCsv('Foo,Bar\n1,2').headerFound, isFalse);
      expect(parseProductsCsv('').headerFound, isFalse);
    });
  });

  group('customers', () {
    test('common headers and the tax number in any country\'s name', () {
      final r = parseCustomersCsv(
          'Customer Name,Mobile No,Email ID,City,VAT No\n'
          'Ravi,+91 98765 43210,r@x.com,Coimbatore,gb123\n');
      final c = r.rows.single;
      expect(c.name, 'Ravi');
      expect(c.phone, '+91 98765 43210');
      expect(c.email, 'r@x.com');
      expect(c.city, 'Coimbatore');
      expect(c.taxId, 'GB123');
    });
  });

  test('duplicate keys ignore case, spacing and country codes', () {
    expect(sameNameKey('Sugar  1 KG'), sameNameKey('sugar 1kg'));
    expect(samePhoneKey('+91 98765-43210'), samePhoneKey('9876543210'));
  });
}
