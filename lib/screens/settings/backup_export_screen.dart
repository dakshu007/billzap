// lib/screens/settings/backup_export_screen.dart
// Backup & Export — single screen for data safety + accountant-friendly CSVs.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../utils/backup_service.dart';
import '../../utils/csv_helper.dart';

class BackupExportScreen extends ConsumerStatefulWidget {
  const BackupExportScreen({super.key});
  @override
  ConsumerState<BackupExportScreen> createState() => _BackupExportState();
}

class _BackupExportState extends ConsumerState<BackupExportScreen> {
  bool _backingUp = false;
  bool _restoring = false;
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final invoices = ref.watch(invoiceProvider);
    final customers = ref.watch(customerProvider);
    final expenses = ref.watch(expenseProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        iconTheme: const IconThemeData(color: AppColors.t1),
        title: Text('Backup & Export',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.t1)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
        children: [
          // ────── BACKUP SECTION ──────
          _SectionHeader(label: 'PROTECT YOUR DATA', icon: Symbols.shield),
          const Gap(8),

          // Backup card
          _BigCard(
            icon: Symbols.cloud_upload,
            iconColor: AppColors.brand,
            title: 'Backup all data',
            subtitle:
                '${invoices.length} invoices • ${customers.length} customers • ${expenses.length} expenses',
            buttonLabel: _backingUp ? 'Creating backup...' : 'Backup now',
            buttonLoading: _backingUp,
            onTap: _backingUp ? null : _startBackup,
          ),
          const Gap(10),
          // Restore card
          _BigCard(
            icon: Symbols.cloud_download,
            iconColor: AppColors.green,
            title: 'Restore from backup',
            subtitle: 'Import a previously saved backup file',
            buttonLabel: _restoring ? 'Restoring...' : 'Choose file',
            buttonLoading: _restoring,
            onTap: _restoring ? null : _startRestore,
          ),
          const Gap(8),
          // Tip card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.yellowSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.yellow.withOpacity(0.3))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Symbols.lightbulb, color: AppColors.orange, size: 16),
              const Gap(8),
              Expanded(child: Text(
                'Backup files are PIN-protected. Send them to yourself via WhatsApp / Email / Drive for safekeeping.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5, color: AppColors.t2, height: 1.5))),
            ]),
          ),

          const Gap(24),

          // ────── EXPORT FOR ACCOUNTANT ──────
          _SectionHeader(label: 'EXPORT FOR ACCOUNTANT (CSV)', icon: Symbols.table_view),
          const Gap(8),
          _ExportTile(
            icon: Symbols.receipt_long,
            iconColor: AppColors.brand,
            title: 'All Invoices',
            subtitle: '${invoices.length} invoices with full GST breakdown',
            disabled: invoices.isEmpty || _exporting,
            onTap: () => _exportInvoicesCsv(),
          ),
          const Gap(8),
          _ExportTile(
            icon: Symbols.calculate,
            iconColor: AppColors.purple,
            title: 'GST Summary (Monthly)',
            subtitle: 'Ready for GSTR-1 filing — month-wise totals',
            disabled: invoices.isEmpty || _exporting,
            onTap: () => _exportGstSummaryCsv(),
          ),
          const Gap(8),
          _ExportTile(
            icon: Symbols.group,
            iconColor: AppColors.green,
            title: 'Customer Ledger',
            subtitle: '${customers.length} customers with billing totals',
            disabled: customers.isEmpty || _exporting,
            onTap: () => _exportCustomersCsv(),
          ),
          const Gap(8),
          _ExportTile(
            icon: Symbols.payments,
            iconColor: AppColors.orange,
            title: 'Expenses',
            subtitle: '${expenses.length} expense records',
            disabled: expenses.isEmpty || _exporting,
            onTap: () => _exportExpensesCsv(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BACKUP FLOW
  // ═══════════════════════════════════════════════════════════════
  Future<void> _startBackup() async {
    final pin = await _askForPin(
      title: 'Set backup PIN',
      message:
          'Choose a 4-digit PIN to protect this backup. You\'ll need it to restore.',
      requireConfirm: true,
    );
    if (pin == null) return;

    setState(() => _backingUp = true);
    final result = await BackupService.createBackup(pin: pin);
    if (!mounted) return;
    setState(() => _backingUp = false);

    if (!result.success) {
      _showError(result.error ?? 'Backup failed');
      return;
    }

    // Share the backup file
    final filePath = result.filePath!;
    final fileName = filePath.split('/').last;
    try {
      await Share.shareXFiles(
        [XFile(filePath, mimeType: 'application/octet-stream')],
        subject: 'BillZap Backup',
        text: 'BillZap backup saved on ${DateFormat('dd MMM yyyy').format(DateTime.now())}.\n\nKeep this file safe — you\'ll need your PIN to restore it.',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Backup created • $fileName'),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3)));
    } catch (e) {
      if (!mounted) return;
      _showError('Share failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // RESTORE FLOW
  // ═══════════════════════════════════════════════════════════════
  Future<void> _startRestore() async {
    // Confirm overwrite first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text(
          'This will REPLACE existing data with the backup contents. '
          'Any current data not in the backup will be lost.\n\n'
          'Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    // Pick file
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: FileType.any,  // .billzap may not be recognized as a known type
        allowMultiple: false,
      );
    } catch (e) {
      _showError('File picker failed: $e');
      return;
    }
    if (picked == null || picked.files.isEmpty) return;
    final filePath = picked.files.first.path;
    if (filePath == null) {
      _showError('Could not access selected file');
      return;
    }

    // Ask for PIN
    if (!mounted) return;
    final pin = await _askForPin(
      title: 'Enter backup PIN',
      message: 'Enter the 4-digit PIN you set when creating this backup.',
      requireConfirm: false,
    );
    if (pin == null) return;

    setState(() => _restoring = true);
    final result = await BackupService.restoreBackup(filePath: filePath, pin: pin);
    if (!mounted) return;
    setState(() => _restoring = false);

    if (!result.success) {
      _showError(result.error ?? 'Restore failed');
      return;
    }

    // Refresh providers
    ref.invalidate(invoiceProvider);
    ref.invalidate(customerProvider);
    ref.invalidate(productProvider);
    ref.invalidate(expenseProvider);
    ref.invalidate(businessProvider);

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Symbols.check_circle, color: AppColors.green),
          SizedBox(width: 10),
          Text('Restore complete'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ${result.invoiceCount} invoices'),
            Text('• ${result.customerCount} customers'),
            Text('• ${result.productCount} products'),
            Text('• ${result.expenseCount} expenses'),
          ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK')),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CSV EXPORTS
  // ═══════════════════════════════════════════════════════════════
  Future<void> _exportInvoicesCsv() async {
    final invoices = ref.read(invoiceProvider);
    if (invoices.isEmpty) {
      _showError('No invoices to export');
      return;
    }
    await _shareCsv(
      content: CsvHelper.invoicesToCsv(invoices),
      filename: 'BillZap_Invoices_${_dateStamp()}.csv',
      subject: 'BillZap Invoices',
    );
  }

  Future<void> _exportGstSummaryCsv() async {
    final invoices = ref.read(invoiceProvider);
    if (invoices.isEmpty) {
      _showError('No invoices to export');
      return;
    }
    await _shareCsv(
      content: CsvHelper.gstSummaryToCsv(invoices),
      filename: 'BillZap_GST_Summary_${_dateStamp()}.csv',
      subject: 'BillZap GST Summary',
    );
  }

  Future<void> _exportCustomersCsv() async {
    final customers = ref.read(customerProvider);
    if (customers.isEmpty) {
      _showError('No customers to export');
      return;
    }
    final invoices = ref.read(invoiceProvider);
    await _shareCsv(
      content: CsvHelper.customersToCsv(customers, invoices),
      filename: 'BillZap_Customers_${_dateStamp()}.csv',
      subject: 'BillZap Customers',
    );
  }

  Future<void> _exportExpensesCsv() async {
    final expenses = ref.read(expenseProvider);
    if (expenses.isEmpty) {
      _showError('No expenses to export');
      return;
    }
    await _shareCsv(
      content: CsvHelper.expensesToCsv(expenses),
      filename: 'BillZap_Expenses_${_dateStamp()}.csv',
      subject: 'BillZap Expenses',
    );
  }

  Future<void> _shareCsv({
    required String content,
    required String filename,
    required String subject,
  }) async {
    setState(() => _exporting = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(content);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: subject,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Exported • $filename'),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (!mounted) return;
      _showError('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _dateStamp() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // ═══════════════════════════════════════════════════════════════
  // PIN INPUT DIALOG
  // ═══════════════════════════════════════════════════════════════
  Future<String?> _askForPin({
    required String title,
    required String message,
    required bool requireConfirm,
  }) async {
    final pin1Ctrl = TextEditingController();
    final pin2Ctrl = TextEditingController();
    String? error;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) {
        return AlertDialog(
          title: Text(title,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.t2)),
              const Gap(16),
              TextField(
                controller: pin1Ctrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 8,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: requireConfirm ? 'PIN' : 'Enter PIN',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  counterText: '',
                ),
                style: GoogleFonts.plusJakartaSans(fontSize: 18, letterSpacing: 6),
              ),
              if (requireConfirm) ...[
                const Gap(10),
                TextField(
                  controller: pin2Ctrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 8,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Confirm PIN',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    counterText: '',
                  ),
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, letterSpacing: 6),
                ),
              ],
              if (error != null) ...[
                const Gap(8),
                Text(error!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: AppColors.red, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final p1 = pin1Ctrl.text.trim();
                if (p1.length < 4) {
                  ss(() => error = 'PIN must be at least 4 digits');
                  return;
                }
                if (requireConfirm) {
                  if (p1 != pin2Ctrl.text.trim()) {
                    ss(() => error = 'PINs do not match');
                    return;
                  }
                }
                Navigator.pop(ctx, p1);
              },
              child: const Text('OK')),
          ],
        );
      }),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.red,
      behavior: SnackBarBehavior.floating));
  }
}

// ═══════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ═══════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 14, color: AppColors.t3),
      const Gap(6),
      Text(label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w800,
          color: AppColors.t3, letterSpacing: 0.8)),
    ]);
  }
}

class _BigCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool buttonLoading;
  final VoidCallback? onTap;
  const _BigCard({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle,
    required this.buttonLabel, this.buttonLoading = false,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: iconColor, size: 26),
        ),
        const Gap(12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.t1)),
            const Gap(2),
            Text(subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5, color: AppColors.t3)),
            const Gap(8),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: const Size(0, 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: buttonLoading
                ? const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(buttonLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ])),
      ]),
    );
  }
}

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool disabled;
  final VoidCallback onTap;
  const _ExportTile({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle,
    this.disabled = false, required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : () { HapticFeedback.lightImpact(); onTap(); },
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: disabled ? AppColors.bg : iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icon,
              color: disabled ? AppColors.t4 : iconColor, size: 20),
          ),
          const Gap(11),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5, fontWeight: FontWeight.w700,
                  color: disabled ? AppColors.t4 : AppColors.t1)),
              Text(subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: AppColors.t3)),
            ])),
          Icon(Symbols.share,
            size: 18, color: disabled ? AppColors.t4 : AppColors.t3),
        ]),
      ),
    );
  }
}
