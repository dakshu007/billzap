// lib/screens/invoice/invoice_preview_screen.dart
// ✅ PDF loading FIXED — StatefulWidget + try/catch/finally
// ✅ Correct model fields — totalCgst/Sgst/Igst, lineItems
// ✅ Zero Firebase
import 'package:flutter/material.dart';
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

class InvoicePreviewScreen extends ConsumerStatefulWidget {
  const InvoicePreviewScreen({super.key});
  @override
  ConsumerState<InvoicePreviewScreen> createState() => _PreviewState();
}

class _PreviewState extends ConsumerState<InvoicePreviewScreen> {
  bool _pdfLoading   = false;
  bool _printLoading = false;

  @override
  Widget build(BuildContext context) {
    final invoice = ref.watch(selectedInvoiceProvider);
    final biz     = ref.watch(businessProvider);

    if (invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice')),
        body: const Center(child: Text('No invoice selected')));
    }

    final c = invoice.status == InvoiceStatus.paid ? AppColors.green
        : invoice.isOverdue ? AppColors.red : AppColors.yellow;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        leading: IconButton(
          icon: Container(width: 34, height: 34,
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_rounded, size: 19, color: AppColors.t1)),
          onPressed: () => context.canPop() ? context.pop() : context.go('/invoices')),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Invoice Preview', style: GoogleFonts.nunito(
            fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1)),
          Text(invoice.invoiceNumber, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.t3)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.t1),
            onPressed: () => _moreOptions(invoice, biz)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 110),
        children: [
          // Status badge
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(99),
                border: Border.all(color: c.withOpacity(0.3))),
              child: Text(invoice.isOverdue ? 'OVERDUE' : invoice.status.name.toUpperCase(),
                style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w800, color: c))),
            if (invoice.isOverdue) ...[
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.redSoft, borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.red.withOpacity(0.3))),
                child: Text('OVERDUE', style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.red))),
            ],
          ]),
          const Gap(12),

          // Invoice document
          _buildDoc(invoice, biz),
          const Gap(12),

          // Action tiles
          _ActionTile('\ud83d\udcc4', 'Download & Share PDF', 'Professional GST invoice PDF',
            loading: _pdfLoading, onTap: () => _downloadPdf(invoice, biz)),
          const Gap(8),
          _ActionTile('\ud83d\udda8\ufe0f', 'Print Invoice', 'Print via WiFi or Bluetooth',
            loading: _printLoading, onTap: () => _printInvoice(invoice, biz)),
          const Gap(8),
          _ActionTile('\u2705', 'Mark as Paid', 'Record payment received',
            onTap: () => _markPaid(invoice)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(invoice, biz),
    );
  }

  Widget _buildDoc(Invoice invoice, Business? biz) {
    return Container(
      decoration: BoxDecoration(color: AppColors.card,
        borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.brand.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Blue header
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(biz?.name ?? 'Your Business', style: GoogleFonts.nunito(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              if (biz?.gstin.isNotEmpty == true)
                Text('GSTIN: ${biz!.gstin}', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 11)),
              if (biz?.address.isNotEmpty == true)
                Text('${biz!.address}${biz.city.isNotEmpty ? ", ${biz.city}" : ""}',
                  style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 10)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('TAX INVOICE', style: GoogleFonts.dmSans(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const Gap(2),
              Text(invoice.invoiceNumber, style: GoogleFonts.nunito(
                color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ])),
        Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Bill to
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('BILL TO', style: GoogleFonts.dmSans(
                  fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.t3, letterSpacing: 0.8)),
                const Gap(4),
                Text(invoice.customerName, style: GoogleFonts.nunito(
                  fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.t1)),
                if (invoice.customerPhone.isNotEmpty)
                  Text(invoice.customerPhone, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.t2)),
                if (invoice.customerGstin.isNotEmpty)
                  Text('GSTIN: ${invoice.customerGstin}',
                    style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.t3)),
                if (invoice.customerAddress.isNotEmpty)
                  Text(invoice.customerAddress, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.t3)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _IRow('Date', DateFormat('dd MMM yyyy').format(invoice.invoiceDate)),
                _IRow('Due', DateFormat('dd MMM yyyy').format(invoice.dueDate)),
                _IRow('Place', invoice.placeOfSupply.length > 14
                  ? invoice.placeOfSupply.substring(0, 14) : invoice.placeOfSupply),
              ]),
            ]),
            const Gap(14),
            const Divider(height: 1),
            const Gap(12),
            // Items header
            Row(children: [
              Expanded(flex: 3, child: _TH('ITEM')),
              Expanded(child: _TH('QTY', right: true)),
              Expanded(child: _TH('RATE', right: true)),
              Expanded(child: _TH('AMT', right: true)),
            ]),
            const Gap(6),
            // Items
            ...invoice.lineItems.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.name, style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.t1)),
                  if (item.hsnCode.isNotEmpty)
                    Text('HSN: ${item.hsnCode}', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.t3)),
                ])),
                Expanded(child: Text('${item.quantity.toInt()}',
                  style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.t2), textAlign: TextAlign.right)),
                Expanded(child: Text(formatCurrency(item.rate),
                  style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.t2), textAlign: TextAlign.right)),
                Expanded(child: Text(formatCurrency(item.taxable), textAlign: TextAlign.right,
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.t1))),
              ])),
            ),
            const Gap(10),
            const Divider(height: 1),
            const Gap(8),
            // Totals
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
                Text('GRAND TOTAL', style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.brand)),
                Text(formatCurrency(invoice.grandTotal), style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900, fontSize: 19, color: AppColors.brand)),
              ])),
            // Bank details
            if (biz != null && (biz.bankName.isNotEmpty || biz.upiId.isNotEmpty)) ...[
              const Gap(14), const Divider(height: 1), const Gap(8),
              Text('PAYMENT DETAILS', style: GoogleFonts.dmSans(
                fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.t3, letterSpacing: 0.8)),
              const Gap(4),
              if (biz.bankName.isNotEmpty)
                Text('${biz.bankName}  \u00b7  A/C: ${biz.accountNumber}  \u00b7  IFSC: ${biz.ifscCode}',
                  style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.t2)),
              if (biz.upiId.isNotEmpty)
                Text('UPI: ${biz.upiId}', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.t2)),
            ],
            if (invoice.notes.isNotEmpty) ...[
              const Gap(10),
              Text('Note: ${invoice.notes}', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.t2)),
            ],
            const Gap(10),
            Center(child: Text('Generated by BillZap \u26a1',
              style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.t4))),
          ])),
      ]),
    );
  }

  Widget _buildBottomBar(Invoice invoice, Business? biz) => Container(
    padding: EdgeInsets.fromLTRB(14, 12, 14, MediaQuery.of(context).padding.bottom + 12),
    decoration: const BoxDecoration(color: Colors.white,
      border: Border(top: BorderSide(color: AppColors.border))),
    child: Row(children: [
      Expanded(flex: 2, child: ElevatedButton.icon(
        onPressed: () => _sendWhatsApp(invoice),
        icon: const Text('\ud83d\udcf2', style: TextStyle(fontSize: 16)),
        label: Text('WhatsApp', style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 14)),
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
          : const Icon(Icons.picture_as_pdf_rounded, size: 18),
        label: Text('PDF', style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
    ]),
  );

  void _moreOptions(Invoice invoice, Business? biz) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99))),
          const Gap(16),
          _OptTile('\ud83d\udcc4', 'Download PDF', () { Navigator.pop(context); _downloadPdf(invoice, biz); }),
          _OptTile('\ud83d\udda8\ufe0f', 'Print Invoice', () { Navigator.pop(context); _printInvoice(invoice, biz); }),
          _OptTile('\u2705', 'Mark as Paid', () { Navigator.pop(context); _markPaid(invoice); }),
          _OptTile('\ud83d\udd14', 'Send WhatsApp Reminder', () { Navigator.pop(context); _sendWhatsApp(invoice); }),
          _OptTile('\ud83d\uddd1\ufe0f', 'Delete Invoice', () { Navigator.pop(context); _deleteInvoice(invoice); },
            color: AppColors.red),
        ])));
  }

  // ── PDF generation (static — shared) ────────────────────────────────────
  static Future<pw.Document> buildPdf(Invoice invoice, Business? biz) async {
    final doc  = pw.Document();
    final cgst = invoice.totalCgst;
    final sgst = invoice.totalSgst;
    final igst = invoice.totalIgst;
    final gr   = invoice.gstRateForDisplay;

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        // Header
        pw.Container(
          padding: const pw.EdgeInsets.all(18),
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF1557FF),
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(biz?.name ?? 'Business Name',
                style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
              if (biz?.gstin.isNotEmpty == true)
                pw.Text('GSTIN: ${biz!.gstin}', style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 10)),
              if (biz?.address.isNotEmpty == true)
                pw.Text('${biz!.address}, ${biz.city}', style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 10)),
              if (biz?.phone.isNotEmpty == true)
                pw.Text('Ph: ${biz!.phone}', style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 10)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('TAX INVOICE', style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(invoice.invoiceNumber, style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 11)),
            ]),
          ])),
        pw.SizedBox(height: 16),
        // Bill to
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('BILL TO', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
            pw.SizedBox(height: 3),
            pw.Text(invoice.customerName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (invoice.customerPhone.isNotEmpty) pw.Text(invoice.customerPhone, style: const pw.TextStyle(fontSize: 10)),
            if (invoice.customerGstin.isNotEmpty) pw.Text('GSTIN: ${invoice.customerGstin}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            if (invoice.customerAddress.isNotEmpty) pw.Text(invoice.customerAddress,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('Date: ${DateFormat('dd MMM yyyy').format(invoice.invoiceDate)}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Due:  ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Place: ${invoice.placeOfSupply}', style: const pw.TextStyle(fontSize: 10)),
          ]),
        ]),
        pw.SizedBox(height: 16), pw.Divider(), pw.SizedBox(height: 8),
        // Items table
        pw.Table(
          columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5), 3: const pw.FlexColumnWidth(1.5)},
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEBF0FF)),
              children: ['DESCRIPTION', 'QTY', 'RATE', 'AMOUNT'].map((h) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(h, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)))).toList()),
            ...invoice.lineItems.map((item) => pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(6),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(item.name, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  if (item.hsnCode.isNotEmpty) pw.Text('HSN: ${item.hsnCode}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ])),
              pw.Padding(padding: const pw.EdgeInsets.all(6),
                child: pw.Text('${item.quantity.toInt()}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 11))),
              pw.Padding(padding: const pw.EdgeInsets.all(6),
                child: pw.Text('\u20b9${item.rate.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 11))),
              pw.Padding(padding: const pw.EdgeInsets.all(6),
                child: pw.Text('\u20b9${item.taxable.toStringAsFixed(2)}', textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
            ])),
          ]),
        pw.SizedBox(height: 12),
        // Totals
        pw.Align(alignment: pw.Alignment.centerRight, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          _pRow('Subtotal', invoice.subtotal),
          if (cgst > 0) _pRow('CGST (${gr/2}%)', cgst),
          if (sgst > 0) _pRow('SGST (${gr/2}%)', sgst),
          if (igst > 0) _pRow('IGST ($gr%)', igst),
          if (invoice.shippingCharge > 0) _pRow('Shipping', invoice.shippingCharge),
          if (invoice.flatDiscount > 0) _pRow('Discount', -invoice.flatDiscount),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1557FF),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6))),
            child: pw.Row(children: [
              pw.Text('GRAND TOTAL   ', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 13)),
              pw.Text('\u20b9${invoice.grandTotal.toStringAsFixed(2)}',
                style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 16)),
            ])),
        ])),
        // Bank
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
        pw.Center(child: pw.Text("Generated by BillZap \u26a1 \u2014 India's Free GST Billing App",
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500))),
      ]),
    ));
    return doc;
  }

  static pw.Widget _pRow(String label, double amount) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(children: [
      pw.Text('$label:   ', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
      pw.Text(amount < 0 ? '-\u20b9${(-amount).toStringAsFixed(2)}' : '\u20b9${amount.toStringAsFixed(2)}',
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
    ]));

  // ── Actions ───────────────────────────────────────────────────────────────
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
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Invoice ${invoice.invoiceNumber}',
        text: 'Invoice ${invoice.invoiceNumber} \u2014 ${formatCurrency(invoice.grandTotal)}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('PDF generated \u2713'), backgroundColor: AppColors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF error: $e'), backgroundColor: AppColors.red));
    } finally {
      // ✅ ALWAYS resets — button never freezes
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
      content: Text('Marked as paid \u2713'), backgroundColor: AppColors.green));
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Invoice?'),
      content: Text('${invoice.invoiceNumber} will be permanently deleted.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete', style: TextStyle(color: AppColors.red))),
      ]));
    if (ok == true) {
      await ref.read(invoiceProvider.notifier).delete(invoice.id);
      if (mounted) context.go('/invoices');
    }
  }

  void _sendWhatsApp(Invoice invoice) async {
    final phone = invoice.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent(
      'Hi ${invoice.customerName},\n\nYour invoice *${invoice.invoiceNumber}* '
      'for *${formatCurrency(invoice.grandTotal)}* is ready.\n\n'
      'Due: ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}\n\n'
      'Thank you! \ud83d\ude4f\n\n\u2014 Sent via BillZap \u26a1');
    final url = Uri.parse('https://wa.me/91$phone?text=$msg');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────
Widget _IRow(String l, String v) => Padding(
  padding: const EdgeInsets.only(bottom: 3),
  child: Row(children: [
    Text('$l: ', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.t3)),
    Text(v, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.t1)),
  ]));

Widget _TH(String t, {bool right = false}) => Text(t,
  textAlign: right ? TextAlign.right : TextAlign.left,
  style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.t3, letterSpacing: 0.5));

Widget _TotRow(String label, double amount, {bool neg = false}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 2),
  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.t2)),
    Text(neg ? '- ${formatCurrency(amount)}' : formatCurrency(amount),
      style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600,
        color: neg ? AppColors.green : AppColors.t1)),
  ]));

class _ActionTile extends StatelessWidget {
  final String emoji, title, sub;
  final bool loading;
  final VoidCallback onTap;
  const _ActionTile(this.emoji, this.title, this.sub, {this.loading = false, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: loading ? AppColors.bg : AppColors.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border)),
      child: Row(children: [
        loading
          ? const SizedBox(width: 28, height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.brand))
          : Text(emoji, style: const TextStyle(fontSize: 22)),
        const Gap(12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.t1)),
          Text(sub, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.t3)),
        ])),
        const Icon(Icons.chevron_right_rounded, color: AppColors.t3),
      ])));
}

class _OptTile extends StatelessWidget {
  final String emoji, label;
  final VoidCallback onTap;
  final Color? color;
  const _OptTile(this.emoji, this.label, this.onTap, {this.color});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Text(emoji, style: const TextStyle(fontSize: 22)),
    title: Text(label, style: GoogleFonts.dmSans(fontWeight: FontWeight.w700,
      color: color ?? AppColors.t1)),
    onTap: onTap);
}
