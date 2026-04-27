// lib/screens/invoice/invoice_preview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../i18n/translations.dart';

class InvoicePreviewScreen extends ConsumerStatefulWidget {
  const InvoicePreviewScreen({super.key});
  @override
  ConsumerState<InvoicePreviewScreen> createState() => _PreviewState();
}

class _PreviewState extends ConsumerState<InvoicePreviewScreen> {
  bool _pdfLoading   = false;
  bool _printLoading = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoice = ref.watch(selectedInvoiceProvider);
    final biz     = ref.watch(businessProvider);

    if (invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice')),
        body: const Center(child: Text('No invoice selected')));
    }

    final isPaid = invoice.status == InvoiceStatus.paid;
    final c = isPaid ? AppColors.green
        : invoice.isOverdue ? AppColors.red : AppColors.yellow;

    // ✅ PopScope: back → /invoices (not /home, since we came from invoices)
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          HapticFeedback.lightImpact();
          context.go('/invoices');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.card,
          leading: IconButton(
            icon: Container(width: 34, height: 34,
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Symbols.arrow_back, size: 19, color: AppColors.t1)),
            onPressed: () => context.go('/invoices')),
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Invoice Preview', style: GoogleFonts.plusJakartaSans(
              fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1)),
            Text(invoice.invoiceNumber, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.t3)),
          ]),
          actions: [
            if (!isPaid)
              IconButton(
                icon: const Icon(Symbols.edit, color: AppColors.brand),
                onPressed: () => _editInvoice(context, invoice)),
            IconButton(
              icon: const Icon(Symbols.more_vert, color: AppColors.t1),
              onPressed: () => _moreOptions(invoice, biz)),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 110),
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: c.withOpacity(0.3))),
                child: Text(invoice.isOverdue ? 'OVERDUE' : invoice.status.name.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: c))),
            ]),
            const Gap(12),
            _buildDoc(invoice, biz),
            const Gap(12),

            // ✅ Material Symbols action tiles
            _ActionTile(
              icon: Symbols.picture_as_pdf, iconColor: AppColors.brand,
              title: 'Download & Share PDF', sub: 'Professional GST invoice PDF',
              loading: _pdfLoading, onTap: () => _downloadPdf(invoice, biz)),
            const Gap(8),
            _ActionTile(
              icon: Symbols.print, iconColor: AppColors.t2,
              title: 'Print Invoice', sub: 'Print via WiFi or Bluetooth',
              loading: _printLoading, onTap: () => _printInvoice(invoice, biz)),
            const Gap(8),
            if (!isPaid)
              _ActionTile(
                icon: Symbols.check_circle, iconColor: AppColors.green,
                title: 'Mark as Paid', sub: 'Record payment received',
                onTap: () => _markPaid(invoice))
            else
              _ActionTile(
                icon: Symbols.undo, iconColor: AppColors.orange,
                title: 'Mark as Unpaid', sub: 'Undo paid status',
                color: AppColors.orange, onTap: () => _markUnpaid(invoice)),
            const Gap(8),
            _ActionTile(
              icon: Symbols.delete, iconColor: AppColors.red,
              title: 'Delete Invoice', sub: 'Permanently remove this invoice',
              color: AppColors.red, onTap: () => _deleteInvoice(invoice)),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(invoice, biz),
      ),
    );
  }

  void _editInvoice(BuildContext context, Invoice invoice) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _EditInvoiceSheet(invoice: invoice));
  }

  Widget _buildDoc(Invoice invoice, Business? biz) {
    return Container(
      decoration: BoxDecoration(color: AppColors.card,
        borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.brand.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(color: AppColors.brand,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(biz?.name ?? 'Your Business', style: GoogleFonts.plusJakartaSans(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              if (biz?.gstin.isNotEmpty == true)
                Text('GSTIN: ${biz!.gstin}', style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11)),
              if (biz?.address.isNotEmpty == true)
                Text('${biz!.address}${biz.city.isNotEmpty ? ", ${biz.city}" : ""}',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 10)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('TAX INVOICE', style: GoogleFonts.plusJakartaSans(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const Gap(2),
              Text(invoice.invoiceNumber, style: GoogleFonts.plusJakartaSans(
                color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ])),
        Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('BILL TO', style: GoogleFonts.plusJakartaSans(
                fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.t3, letterSpacing: 0.8)),
              const Gap(4),
              Text(invoice.customerName, style: GoogleFonts.plusJakartaSans(
                fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.t1)),
              if (invoice.customerPhone.isNotEmpty)
                Text(invoice.customerPhone, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.t2)),
              if (invoice.customerGstin.isNotEmpty)
                Text('GSTIN: ${invoice.customerGstin}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.t3)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _IRow('Date', DateFormat('dd MMM yyyy').format(invoice.invoiceDate)),
              _IRow('Due', DateFormat('dd MMM yyyy').format(invoice.dueDate)),
            ]),
          ]),
          const Gap(14),
          const Divider(height: 1),
          const Gap(12),
          Row(children: [
            Expanded(flex: 3, child: _TH('ITEM')),
            Expanded(child: _TH('QTY', right: true)),
            Expanded(child: _TH('RATE', right: true)),
            Expanded(child: _TH('AMT', right: true)),
          ]),
          const Gap(6),
          ...invoice.lineItems.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.name, style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.t1)),
                if (item.hsnCode.isNotEmpty)
                  Text('HSN: ${item.hsnCode}', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.t3)),
              ])),
              Expanded(child: Text('${item.quantity.toInt()}',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.t2), textAlign: TextAlign.right)),
              Expanded(child: Text(formatCurrency(item.rate),
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.t2), textAlign: TextAlign.right)),
              Expanded(child: Text(formatCurrency(item.taxable), textAlign: TextAlign.right,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.t1))),
            ])),
          ),
          const Gap(10),
          const Divider(height: 1),
          const Gap(8),
          _TotRow('Subtotal', invoice.subtotal),
          if (invoice.totalCgst > 0) _TotRow('CGST (${invoice.gstRateForDisplay/2}%)', invoice.totalCgst),
          if (invoice.totalSgst > 0) _TotRow('SGST (${invoice.gstRateForDisplay/2}%)', invoice.totalSgst),
          if (invoice.totalIgst > 0) _TotRow('IGST (${invoice.gstRateForDisplay}%)', invoice.totalIgst),
          if (invoice.shippingCharge > 0) _TotRow('Shipping', invoice.shippingCharge),
          if (invoice.flatDiscount > 0) _TotRow('Discount', invoice.flatDiscount, neg: true),
          const Gap(6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('GRAND TOTAL', style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.brand)),
              Text(formatCurrency(invoice.grandTotal), style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w900, fontSize: 19, color: AppColors.brand)),
            ])),
          if (biz != null && (biz.bankName.isNotEmpty || biz.upiId.isNotEmpty)) ...[
            const Gap(14), const Divider(height: 1), const Gap(8),
            Text('PAYMENT DETAILS', style: GoogleFonts.plusJakartaSans(
              fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.t3, letterSpacing: 0.8)),
            const Gap(4),
            if (biz.bankName.isNotEmpty)
              Text('${biz.bankName}  ·  A/C: ${biz.accountNumber}  ·  IFSC: ${biz.ifscCode}',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.t2)),
            if (biz.upiId.isNotEmpty)
              Text('UPI: ${biz.upiId}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.t2)),
          ],
          if (invoice.notes.isNotEmpty) ...[
            const Gap(10),
            Text('Note: ${invoice.notes}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.t2)),
          ],
          const Gap(10),
          Center(child: Text('Generated by BillZap ⚡',
            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.t4))),
        ])),
      ]),
    );
  }

  Widget _buildBottomBar(Invoice invoice, Business? biz) => Container(
    padding: EdgeInsets.fromLTRB(14, 12, 14, MediaQuery.of(context).padding.bottom + 12),
    decoration: const BoxDecoration(color: Colors.white,
      border: Border(top: BorderSide(color: AppColors.border))),
    child: Row(children: [
      // ✅ WhatsApp button with Material Symbol icon
      Expanded(flex: 2, child: ElevatedButton.icon(
        onPressed: () => _sendWhatsApp(invoice),
        icon: const Icon(Symbols.chat, size: 18),
        label: Text('WhatsApp', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
      const Gap(10),
      Expanded(child: ElevatedButton.icon(
        onPressed: _pdfLoading ? null : () => _downloadPdf(invoice, biz),
        icon: _pdfLoading
          ? const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Symbols.picture_as_pdf, size: 18),
        label: Text('PDF', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
    ]),
  );

  void _moreOptions(Invoice invoice, Business? biz) {
    final isPaid = invoice.status == InvoiceStatus.paid;
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99))),
          const Gap(16),
          if (!isPaid) _OptTile(Symbols.edit, 'Edit Invoice', AppColors.brand,
            () { Navigator.pop(context); _editInvoice(context, invoice); }),
          _OptTile(Symbols.picture_as_pdf, 'Download PDF', AppColors.brand,
            () { Navigator.pop(context); _downloadPdf(invoice, biz); }),
          _OptTile(Symbols.print, 'Print Invoice', AppColors.t2,
            () { Navigator.pop(context); _printInvoice(invoice, biz); }),
          _OptTile(Symbols.chat, 'Send WhatsApp', const Color(0xFF25D366),
            () { Navigator.pop(context); _sendWhatsApp(invoice); }),
          if (!isPaid)
            _OptTile(Symbols.check_circle, 'Mark as Paid', AppColors.green,
              () { Navigator.pop(context); _markPaid(invoice); })
          else
            _OptTile(Symbols.undo, 'Mark as Unpaid', AppColors.orange,
              () { Navigator.pop(context); _markUnpaid(invoice); }),
          _OptTile(Symbols.delete, 'Delete Invoice', AppColors.red,
            () { Navigator.pop(context); _deleteInvoice(invoice); }),
        ])));
  }

  static Future<pw.Document> buildPdf(Invoice invoice, Business? biz) async {
    final doc = pw.Document();
    final cgst = invoice.totalCgst;
    final sgst = invoice.totalSgst;
    final igst = invoice.totalIgst;
    final gr   = invoice.gstRateForDisplay;
    String rs(double amount) {
      final abs = amount.abs();
      final parts = abs.toStringAsFixed(2).split('.');
      String integer = parts[0];
      if (integer.length > 3) {
        final last3 = integer.substring(integer.length - 3);
        final rest = integer.substring(0, integer.length - 3);
        final groups = <String>[];
        for (var i = rest.length; i > 0; i -= 2) {
          groups.insert(0, rest.substring(i < 2 ? 0 : i - 2, i));
        }
        integer = '${groups.join(',')},${last3}';
      }
      return '${amount < 0 ? '-' : ''}Rs.$integer.${parts[1]}';
    }
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(18),
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1557FF),
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(biz?.name ?? 'Business Name',
                style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
              if (biz?.gstin.isNotEmpty == true)
                pw.Text('GSTIN: ${biz!.gstin}', style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 10)),
              if (biz?.address.isNotEmpty == true)
                pw.Text('${biz!.address}, ${biz.city}', style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 10)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('TAX INVOICE',
                style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(invoice.invoiceNumber, style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 11)),
            ]),
          ])),
        pw.SizedBox(height: 16),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('BILL TO', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
            pw.SizedBox(height: 3),
            pw.Text(invoice.customerName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (invoice.customerPhone.isNotEmpty)
              pw.Text(invoice.customerPhone, style: const pw.TextStyle(fontSize: 10)),
            if (invoice.customerGstin.isNotEmpty)
              pw.Text('GSTIN: ${invoice.customerGstin}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('Date: ${DateFormat('dd MMM yyyy').format(invoice.invoiceDate)}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Due:  ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}', style: const pw.TextStyle(fontSize: 10)),
          ]),
        ]),
        pw.SizedBox(height: 16), pw.Divider(), pw.SizedBox(height: 8),
        pw.Table(
          columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5), 3: const pw.FlexColumnWidth(1.5)},
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEBF0FF)),
              children: ['DESCRIPTION','QTY','RATE','AMOUNT'].map((h) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(h, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)))).toList()),
            ...invoice.lineItems.map((item) => pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(item.name, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  if (item.hsnCode.isNotEmpty)
                    pw.Text('HSN: ${item.hsnCode}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ])),
              pw.Padding(padding: const pw.EdgeInsets.all(6),
                child: pw.Text('${item.quantity.toInt()}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 11))),
              pw.Padding(padding: const pw.EdgeInsets.all(6),
                child: pw.Text(rs(item.rate), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 11))),
              pw.Padding(padding: const pw.EdgeInsets.all(6),
                child: pw.Text(rs(item.taxable), textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
            ])),
          ]),
        pw.SizedBox(height: 12),
        pw.Align(alignment: pw.Alignment.centerRight, child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          _pRow('Subtotal', invoice.subtotal, rs),
          if (cgst > 0) _pRow('CGST (${gr/2}%)', cgst, rs),
          if (sgst > 0) _pRow('SGST (${gr/2}%)', sgst, rs),
          if (igst > 0) _pRow('IGST ($gr%)', igst, rs),
          if (invoice.shippingCharge > 0) _pRow('Shipping', invoice.shippingCharge, rs),
          if (invoice.flatDiscount > 0) _pRow('Discount', -invoice.flatDiscount, rs),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1557FF),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6))),
            child: pw.Row(children: [
              pw.Text('GRAND TOTAL   ', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 13)),
              pw.Text(rs(invoice.grandTotal), style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 16)),
            ])),
        ])),
        if (biz != null && (biz.bankName.isNotEmpty || biz.upiId.isNotEmpty)) ...[
          pw.SizedBox(height: 16), pw.Divider(), pw.SizedBox(height: 8),
          pw.Text('PAYMENT DETAILS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          if (biz.bankName.isNotEmpty)
            pw.Text('Bank: ${biz.bankName}   A/C: ${biz.accountNumber}   IFSC: ${biz.ifscCode}',
              style: const pw.TextStyle(fontSize: 10)),
          if (biz.upiId.isNotEmpty)
            pw.Text('UPI: ${biz.upiId}', style: const pw.TextStyle(fontSize: 10)),
        ],
        if (invoice.notes.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text('Notes: ${invoice.notes}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ],
        pw.SizedBox(height: 20),
        pw.Center(child: pw.Text("Generated by BillZap - India's Free GST Billing App",
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500))),
      ])));
    return doc;
  }

  static pw.Widget _pRow(String label, double amount, String Function(double) rs) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(children: [
      pw.Text('$label:   ', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
      pw.Text(rs(amount), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
    ]));

  Future<void> _downloadPdf(Invoice invoice, Business? biz) async {
    if (_pdfLoading) return;
    setState(() => _pdfLoading = true);
    try {
      final doc   = await buildPdf(invoice, biz);
      final bytes = await doc.save();
      final dir   = await getApplicationDocumentsDirectory();
      final file  = File('${dir.path}/BillZap_${invoice.invoiceNumber}.pdf');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Invoice ${invoice.invoiceNumber}',
        text: 'Invoice ${invoice.invoiceNumber} — ${formatCurrency(invoice.grandTotal)}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('PDF ready ✓'), backgroundColor: AppColors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF error: $e'), backgroundColor: AppColors.red));
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

  Future<void> _printInvoice(Invoice invoice, Business? biz) async {
    if (_printLoading) return;
    setState(() => _printLoading = true);
    try {
      final doc = await buildPdf(invoice, biz);
      await Printing.layoutPdf(onLayout: (_) async => doc.save());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print error: $e'), backgroundColor: AppColors.red));
    } finally {
      if (mounted) setState(() => _printLoading = false);
    }
  }

  Future<void> _markPaid(Invoice invoice) async {
    await ref.read(invoiceProvider.notifier).markPaid(invoice.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Marked as paid ✓'), backgroundColor: AppColors.green));
  }

  Future<void> _markUnpaid(Invoice invoice) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Mark as Unpaid?'),
      content: const Text('This will change the invoice status back to Sent.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true),
          child: const Text('Mark Unpaid', style: TextStyle(color: AppColors.orange))),
      ]));
    if (ok == true) {
      await ref.read(invoiceProvider.notifier).markUnpaid(invoice.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Marked as unpaid'), backgroundColor: AppColors.orange));
    }
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Invoice?'),
      content: Text('${invoice.invoiceNumber} will be permanently deleted.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true),
          child: const Text(tr('common.delete', ref), style: TextStyle(color: AppColors.red))),
      ]));
    if (ok == true) {
      await ref.read(invoiceProvider.notifier).delete(invoice.id);
      if (mounted) context.go('/invoices');
    }
  }

  // ✅ WhatsApp fix: try wa.me with phone, fallback to wa.me without phone
  Future<void> _sendWhatsApp(Invoice invoice) async {
    final msg = Uri.encodeComponent(
      'Hi ${invoice.customerName},\n\n'
      'Your invoice *${invoice.invoiceNumber}* '
      'for *${formatCurrency(invoice.grandTotal)}* is ready.\n\n'
      'Due: ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}\n\n'
      'Thank you! 🙏\n\n— Sent via BillZap ⚡');

    final phone = invoice.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Try with phone number first
    Uri url;
    if (phone.isNotEmpty) {
      final fullPhone = phone.startsWith('91') ? phone : '91$phone';
      url = Uri.parse('https://wa.me/$fullPhone?text=$msg');
    } else {
      url = Uri.parse('https://wa.me/?text=$msg');
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: open WhatsApp directly
        final fallback = Uri.parse('whatsapp://send?text=$msg');
        if (await canLaunchUrl(fallback)) {
          await launchUrl(fallback, mode: LaunchMode.externalApplication);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(tr('msg.whatsapp_not_installed', ref)), backgroundColor: AppColors.red));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red));
    }
  }
}

// ── Edit Invoice Sheet ─────────────────────────────────────────
class _EditInvoiceSheet extends ConsumerStatefulWidget {
  final Invoice invoice;
  const _EditInvoiceSheet({required this.invoice});
  @override
  ConsumerState<_EditInvoiceSheet> createState() => _EditInvoiceSheetState();
}

class _EditInvoiceSheetState extends ConsumerState<_EditInvoiceSheet> {
  late TextEditingController _custName, _custPhone, _custGstin, _notes;
  late DateTime _date, _due;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final inv = widget.invoice;
    _custName  = TextEditingController(text: inv.customerName);
    _custPhone = TextEditingController(text: inv.customerPhone);
    _custGstin = TextEditingController(text: inv.customerGstin);
    _notes     = TextEditingController(text: inv.notes);
    _date = inv.invoiceDate;
    _due  = inv.dueDate;
  }

  @override
  void dispose() {
    _custName.dispose(); _custPhone.dispose();
    _custGstin.dispose(); _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(
      decoration: const BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4,
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99))),
        const Gap(14),
        Text('Edit Invoice', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
        const Gap(16),
        TextField(controller: _custName,
          decoration: InputDecoration(labelText: 'Customer Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
        const Gap(10),
        Row(children: [
          Expanded(child: TextField(controller: _custPhone, keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: 'Phone',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5))),
          const Gap(10),
          Expanded(child: TextField(controller: _custGstin,
            decoration: InputDecoration(labelText: 'GSTIN',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5))),
        ]),
        const Gap(10),
        Row(children: [
          Expanded(child: _DateField('Invoice Date', _date, (d) => setState(() => _date = d))),
          const Gap(10),
          Expanded(child: _DateField('Due Date', _due, (d) => setState(() => _due = d))),
        ]),
        const Gap(10),
        TextField(controller: _notes, maxLines: 2,
          decoration: InputDecoration(labelText: 'Notes',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
        const Gap(16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          child: _saving
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text('Save Changes', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)))),
      ])));

  Widget _DateField(String label, DateTime date, ValueChanged<DateTime> onPick) =>
    GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(context: context,
          initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2035));
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const Icon(Symbols.calendar_today, size: 14, color: AppColors.t3),
          const Gap(6),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.t3)),
            Text(DateFormat('dd MMM yyyy').format(date),
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.t1)),
          ])),
        ])));

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final inv = widget.invoice;
      inv.customerName  = _custName.text.trim();
      inv.customerPhone = _custPhone.text.trim();
      inv.customerGstin = _custGstin.text.trim().toUpperCase();
      inv.notes = _notes.text.trim();
      inv.invoiceDate = _date;
      inv.dueDate = _due;
      await ref.read(invoiceProvider.notifier).update(inv);
      ref.read(selectedInvoiceProvider.notifier).state = inv;
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Invoice updated ✓'), backgroundColor: AppColors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Helper widgets ─────────────────────────────────────────────
Widget _IRow(String l, String v) => Padding(
  padding: const EdgeInsets.only(bottom: 3),
  child: Row(children: [
    Text('$l: ', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.t3)),
    Text(v, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.t1)),
  ]));

Widget _TH(String t, {bool right = false}) => Text(t,
  textAlign: right ? TextAlign.right : TextAlign.left,
  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.t3, letterSpacing: 0.5));

Widget _TotRow(String label, double amount, {bool neg = false}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 2),
  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.t2)),
    Text(neg ? '- ${formatCurrency(amount)}' : formatCurrency(amount),
      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600,
        color: neg ? AppColors.green : AppColors.t1)),
  ]));

// ✅ Action tile with Material Symbol icon
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, sub;
  final bool loading;
  final Color? color;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon, required this.iconColor,
    required this.title, required this.sub,
    this.loading = false, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: loading ? AppColors.bg : AppColors.card,
        borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
          child: loading
            ? const Center(child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.brand)))
            : Icon(icon, size: 20, color: iconColor)),
        const Gap(12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14,
            color: color ?? AppColors.t1)),
          Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.t3)),
        ])),
        Icon(Symbols.chevron_right, color: AppColors.t3),
      ])));
}

// ✅ Options tile with Material Symbol icon
class _OptTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OptTile(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 18, color: color)),
    title: Text(label, style: GoogleFonts.plusJakartaSans(
      fontWeight: FontWeight.w700, color: AppColors.t1)),
    onTap: onTap);
}
