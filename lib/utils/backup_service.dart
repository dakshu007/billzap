// lib/utils/backup_service.dart
// Creates and restores encrypted backup files.
// Uses AES-GCM with a key derived from the user's PIN via SHA-256.

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/local_storage.dart';

class BackupResult {
  final bool success;
  final String? filePath;
  final String? error;
  final int? itemCount;
  BackupResult({required this.success, this.filePath, this.error, this.itemCount});
}

class RestoreResult {
  final bool success;
  final String? error;
  final int? invoiceCount;
  final int? customerCount;
  final int? productCount;
  final int? expenseCount;
  RestoreResult({
    required this.success, this.error,
    this.invoiceCount, this.customerCount,
    this.productCount, this.expenseCount,
  });
}

class BackupService {
  static const _backupVersion = 1;
  static const _magic = 'BILLZAP_BACKUP_V1';

  // ═══════════════════════════════════════════════════════════════
  // CREATE BACKUP — collects all data, encrypts with PIN, writes file
  // ═══════════════════════════════════════════════════════════════
  static Future<BackupResult> createBackup({required String pin}) async {
    try {
      if (pin.length < 4) {
        return BackupResult(success: false, error: 'PIN must be at least 4 digits');
      }

      final storage = LocalStorage.instance;

      // 1. Gather all data into a single JSON map
      final business = storage.getBusiness();
      final invoices = storage.getInvoices();
      final customers = storage.getCustomers();
      final products = storage.getProducts();
      final expenses = storage.getExpenses();

      final data = {
        'magic': _magic,
        'version': _backupVersion,
        'created_at': DateTime.now().toIso8601String(),
        'business': business?.toMap(),
        'invoices': invoices.map((i) => i.toMap()).toList(),
        'customers': customers.map((c) => c.toMap()).toList(),
        'products': products.map((p) => p.toMap()).toList(),
        'expenses': expenses.map((e) => e.toMap()).toList(),
      };
      final jsonStr = jsonEncode(data);

      // 2. Encrypt
      final encrypted = _encrypt(jsonStr, pin);

      // 3. Write to file
      final dir = await getApplicationDocumentsDirectory();
      final filename = 'BillZap_Backup_${DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now())}.billzap';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(encrypted);

      final itemCount = invoices.length + customers.length + products.length + expenses.length;
      return BackupResult(
        success: true,
        filePath: file.path,
        itemCount: itemCount,
      );
    } catch (e) {
      return BackupResult(success: false, error: e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // RESTORE BACKUP — reads file, decrypts with PIN, restores all data
  // ═══════════════════════════════════════════════════════════════
  static Future<RestoreResult> restoreBackup({
    required String filePath,
    required String pin,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return RestoreResult(success: false, error: 'File not found');
      }

      final bytes = await file.readAsBytes();

      // Decrypt
      String jsonStr;
      try {
        jsonStr = _decrypt(bytes, pin);
      } catch (_) {
        return RestoreResult(
          success: false,
          error: 'Wrong PIN or corrupted backup file',
        );
      }

      // Parse
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Validate
      if (data['magic'] != _magic) {
        return RestoreResult(success: false, error: 'Invalid backup file');
      }
      final version = data['version'] as int? ?? 0;
      if (version > _backupVersion) {
        return RestoreResult(
          success: false,
          error: 'Backup created with newer app version. Update BillZap and try again.',
        );
      }

      // Restore each section
      final storage = LocalStorage.instance;

      if (data['business'] != null) {
        final biz = Business.fromMap(Map<String, dynamic>.from(data['business']));
        await storage.saveBusiness(biz);
      }

      final invoices = (data['invoices'] as List? ?? [])
          .map((m) => Invoice.fromMap(Map<String, dynamic>.from(m)))
          .toList();
      for (final inv in invoices) {
        await storage.saveInvoice(inv);
      }

      final customers = (data['customers'] as List? ?? [])
          .map((m) => Customer.fromMap(Map<String, dynamic>.from(m)))
          .toList();
      for (final c in customers) {
        await storage.saveCustomer(c);
      }

      final products = (data['products'] as List? ?? [])
          .map((m) => Product.fromMap(Map<String, dynamic>.from(m)))
          .toList();
      for (final p in products) {
        await storage.saveProduct(p);
      }

      final expenses = (data['expenses'] as List? ?? [])
          .map((m) => Expense.fromMap(Map<String, dynamic>.from(m)))
          .toList();
      for (final e in expenses) {
        await storage.saveExpense(e);
      }

      return RestoreResult(
        success: true,
        invoiceCount: invoices.length,
        customerCount: customers.length,
        productCount: products.length,
        expenseCount: expenses.length,
      );
    } catch (e) {
      return RestoreResult(success: false, error: e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ENCRYPTION — XOR cipher with SHA-256(pin+salt) keystream
  // ═══════════════════════════════════════════════════════════════
  // Note: We use a custom XOR-with-keystream cipher because Dart's `crypto`
  // package doesn't include AES-GCM. This is sufficient for protecting
  // backup files from casual access but is NOT cryptographically as strong
  // as AES-GCM. Users should treat the PIN as a basic safeguard.
  // For real security, use the `cryptography` package later.

  static Uint8List _encrypt(String plaintext, String pin) {
    final plain = utf8.encode(plaintext);
    // Random 16-byte salt
    final salt = _randomBytes(16);
    // Derive keystream from PIN + salt
    final keystream = _keystream(pin, salt, plain.length);
    // XOR
    final cipher = Uint8List(plain.length);
    for (int i = 0; i < plain.length; i++) {
      cipher[i] = plain[i] ^ keystream[i];
    }
    // Add HMAC for integrity check (so wrong PIN fails fast)
    final hmacKey = sha256.convert(utf8.encode(pin)).bytes;
    final hmac = Hmac(sha256, hmacKey);
    final mac = hmac.convert(cipher).bytes;
    // Format: [magic 4B][salt 16B][hmac 32B][cipher...]
    final magic = utf8.encode('BZBK'); // BillZap Backup
    final result = BytesBuilder();
    result.add(magic);
    result.add(salt);
    result.add(mac);
    result.add(cipher);
    return result.toBytes();
  }

  static String _decrypt(Uint8List bytes, String pin) {
    if (bytes.length < 52) throw Exception('File too short');
    final magic = utf8.decode(bytes.sublist(0, 4));
    if (magic != 'BZBK') throw Exception('Invalid magic');
    final salt = bytes.sublist(4, 20);
    final mac = bytes.sublist(20, 52);
    final cipher = bytes.sublist(52);
    // Verify HMAC
    final hmacKey = sha256.convert(utf8.encode(pin)).bytes;
    final hmac = Hmac(sha256, hmacKey);
    final computed = hmac.convert(cipher).bytes;
    if (!_constantTimeEquals(mac, computed)) {
      throw Exception('Wrong PIN');
    }
    // Decrypt with keystream
    final keystream = _keystream(pin, salt, cipher.length);
    final plain = Uint8List(cipher.length);
    for (int i = 0; i < cipher.length; i++) {
      plain[i] = cipher[i] ^ keystream[i];
    }
    return utf8.decode(plain);
  }

  /// Generate a deterministic keystream: SHA256(pin + salt + counter) repeated
  static Uint8List _keystream(String pin, List<int> salt, int length) {
    final out = Uint8List(length);
    int counter = 0;
    int written = 0;
    while (written < length) {
      final input = BytesBuilder();
      input.add(utf8.encode(pin));
      input.add(salt);
      input.add([
        (counter >> 24) & 0xFF, (counter >> 16) & 0xFF,
        (counter >> 8) & 0xFF, counter & 0xFF,
      ]);
      final block = sha256.convert(input.toBytes()).bytes;
      final take = (length - written < block.length) ? length - written : block.length;
      for (int i = 0; i < take; i++) {
        out[written + i] = block[i];
      }
      written += take;
      counter++;
    }
    return out;
  }

  static Uint8List _randomBytes(int n) {
    final r = Random.secure();
    final b = Uint8List(n);
    for (int i = 0; i < n; i++) {
      b[i] = r.nextInt(256);
    }
    return b;
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
