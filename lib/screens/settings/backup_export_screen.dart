// lib/screens/settings/backup_export_screen.dart
// Backup & Export — single screen for data safety + accountant-friendly CSVs.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:billzap/theme/app_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
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
        backgroundColor: AppColors.bg,
        iconTheme: IconThemeData(color: AppColors.t1),
        title: Text('Backup & Export',
          style: AppFont.sans(
            fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.t1)),
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
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.yellow.withOpacity(0.3))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Symbols.lightbulb, color: AppColors.orange, size: 16),
              const Gap(8),
              Expanded(child: Text(
                'Backup files are PIN-protected. Send them to yourself via WhatsApp / Email / Drive for safekeeping.',
                style: AppFont.sans(
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
    final confirmed = await confirm(context,
        title: 'Restore this backup?',
        message: 'Everything on this phone is replaced by what is in the '
            'backup file. Anything not in the file is lost.',
        icon: Symbols.restore,
        destructive: true,
        confirmLabel: 'Replace my data');
    if (!confirmed) return;

    // Pick file
    PlatformFile? picked;
    try {
      // .billzap is not a type the picker knows, so stay on FileType.any.
      picked = await FilePicker.pickFile(type: FileType.any);
    } catch (e) {
      _showError('File picker failed: $e');
      return;
    }
    if (picked == null) return;
    final filePath = picked.path;
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
    notify(context,
        title: 'Restore complete',
        icon: Symbols.check_circle,
        tone: AppColor.paid,
        body: AppWell(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg, vertical: AppSpace.md),
          child: Column(children: [
            _restoredRow('Invoices', result.invoiceCount ?? 0),
            _restoredRow('Customers', result.customerCount ?? 0),
            _restoredRow('Products', result.productCount ?? 0),
            _restoredRow('Expenses', result.expenseCount ?? 0),
          ]),
        ));
  }

  /// One line of the restore summary — label left, count right, in the
  /// same tabular figures the ledger uses so the column is straight.
  Widget _restoredRow(String label, int count) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: AppFont.style(AppType.bodyM,
                    color: AppColor.textSecondary)),
          ),
          Text('$count',
              style: AppFont.style(AppType.numeric,
                  color: AppColor.textPrimary)),
        ]),
      );

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

    return showAppDialog<String>(
      context: context,
      dismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) {
        void submit() {
          final p1 = pin1Ctrl.text.trim();
          if (p1.length < 4) {
            ss(() => error = 'A PIN needs at least 4 digits');
            return;
          }
          if (requireConfirm && p1 != pin2Ctrl.text.trim()) {
            ss(() => error = 'The two PINs are different');
            return;
          }
          Navigator.pop(ctx, p1);
        }

        return AppDialog(
          title: title,
          message: message,
          icon: Symbols.lock,
          confirmLabel: 'Continue',
          onConfirm: submit,
          cancelLabel: 'Cancel',
          onCancel: () => Navigator.pop(ctx),
          body: Column(children: [
            _PinField(
              controller: pin1Ctrl,
              label: requireConfirm ? 'Choose a PIN' : 'Enter PIN',
              autofocus: true,
              onSubmitted: requireConfirm ? null : (_) => submit(),
            ),
            if (requireConfirm) ...[
              const Gap(AppSpace.sm),
              _PinField(
                controller: pin2Ctrl,
                label: 'Type it again',
                onSubmitted: (_) => submit(),
              ),
            ],
            if (error != null) ...[
              const Gap(AppSpace.md),
              Row(children: [
                Icon(Symbols.warning, size: 15, color: AppColor.overdue),
                const Gap(AppSpace.xs),
                Expanded(
                  child: Text(error!,
                      style: AppFont.style(AppType.bodyS,
                          color: AppColor.overdue)),
                ),
              ]),
            ],
          ]),
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
        style: AppFont.sans(
          fontSize: 11, fontWeight: FontWeight.w600,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: iconColor, size: 26),
        ),
        const Gap(12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
              style: AppFont.sans(
                fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.t1)),
            const Gap(2),
            Text(subtitle,
              style: AppFont.sans(
                fontSize: 11.5, color: AppColors.t3)),
            const Gap(8),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: const Size(0, 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: buttonLoading
                ? const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(buttonLabel,
                    style: AppFont.sans(
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: disabled ? AppColors.bg : iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14)),
            child: Icon(icon,
              color: disabled ? AppColors.t4 : iconColor, size: 20),
          ),
          const Gap(11),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: AppFont.sans(
                  fontSize: 13.5, fontWeight: FontWeight.w700,
                  color: disabled ? AppColors.t4 : AppColors.t1)),
              Text(subtitle,
                style: AppFont.sans(
                  fontSize: 11, color: AppColors.t3)),
            ])),
          Icon(Symbols.share,
            size: 18, color: disabled ? AppColors.t4 : AppColors.t3),
        ]),
      ),
    );
  }
}


/// The PIN entry used by the backup dialogs. A recessed well with wide
/// letter-spacing, rather than Material's underlined field — the dialog
/// it sits in has no outlines anywhere else.
class _PinField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  const _PinField({
    required this.controller,
    required this.label,
    this.autofocus = false,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppFont.style(AppType.labelS,
                  color: AppColor.textTertiary)),
          const Gap(AppSpace.xs),
          AppWell(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg, vertical: 2),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              obscuringCharacter: '\u2022',
              maxLength: 8,
              autofocus: autofocus,
              textAlign: TextAlign.center,
              onSubmitted: onSubmitted,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                isDense: true,
              ),
              style: AppFont.style(AppType.titleM,
                      color: AppColor.textPrimary)
                  .copyWith(letterSpacing: 10),
            ),
          ),
        ],
      );
}
