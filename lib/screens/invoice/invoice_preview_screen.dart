// lib/screens/invoice/invoice_preview_screen.dart — all bugs fixed
import 'package:flutter/material.dart';
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

    final isPaid = invoice.status == InvoiceStatus.paid;
    final c = isPaid ? AppColors.green
        : invoice.isOverdue ? AppColors.red : AppColors.yellow;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        leading: IconButton(
          icon: Container(width: 34, height: 34,
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
            child: const Icon(MaterialSymbols.arrow_back, size: 19, color: AppColors.t1)),
          onPressed: () => context.go('/home')),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Invoice Preview', style: GoogleFonts.nunito(
            fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1)),
          Text(invoice.invoiceNumber, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.t3)),
        ]),
        actions: [
          // ✅ EDIT button
          if (!isPaid)
            IconButton(
              icon: const Icon(MaterialSymbols.edit, color: AppColors.brand),
              onPressed: () => _editInvoice(context, invoice)),
          IconButton(
            icon: const Icon(MaterialSymbols.more_vert, color: AppColors.t1),
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
                style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w800, color: c))),
            if (invoice.isOverdue) ...[
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.red.withOpacity(0.3))),
                child: Text('OVERDUE', style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.red))),
            ],
          ]),
          const Gap(12),
          _buildDoc(invoice, biz),
          const Gap(12),
          _ActionTile('📄', 'Download & Share PDF', 'Professional GST invoice PDF',
            loading: _pdfLoading, onTap: () => _downloadPdf(invoice, biz)),
          const Gap(8),
          _ActionTile('🖨️', 'Print Invoice', 'Print via WiFi or Bluetooth',
            loading: _printLoading, onTap: () => _printInvoice(invoice, biz)),
          const Gap(8),
          if (!isPaid)
            _ActionTile('✅', 'Mark as Paid', 'Record payment received',
              onTap: () => _markPaid(invoice))
          else
            _ActionTile('↩️', 'Mark as Unpaid', 'Undo paid status',
              color: AppColors.orange, onTap: () => _markUnpaid(invoice)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(invoice, biz),
    );
  }

  // ✅ Edit invoice — opens edit sheet
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
          if (biz != null && (biz.bankName.isNotEmpty || biz.upiId.isNotEmpty)) ...[
            const Gap(14), const Divider(height: 1), const Gap(8),
            Text('PAYMENT DETAILS', style: GoogleFonts.dmSans(
              fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.t3, letterSpacing: 0.8)),
            const Gap(4),
            if (biz.bankName.isNotEmpty)
              Text('${biz.bankName}  ·  A/C: ${biz.accountNumber}  ·  IFSC: ${biz.ifscCode}',
                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.t2)),
            if (biz.upiId.isNotEmpty)
              Text('UPI: ${biz.upiId}', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.t2)),
          ],
          if (invoice.notes.isNotEmpty) ...[
            const Gap(10),
            Text('Note: ${invoice.notes}', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.t2)),
          ],
          const Gap(10),
          Center(child: Text('Generated by BillZap ⚡',
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
        icon: const Text('📱', style: TextStyle(fontSize: 16)),
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
          : const Icon(MaterialSymbols.picture_as_pdf, size: 18),
        label: Text('PDF', style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 14)),
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
          if (!isPaid) _OptTile('✏️', 'Edit Invoice',
            () { Navigator.pop(context); _editInvoice(context, invoice); }),
          _OptTile('📄', 'Download PDF', () { Navigator.pop(context); _downloadPdf(invoice, biz); }),
          _OptTile('🖨️', 'Print Invoice', () { Navigator.pop(context); _printInvoice(invoice, biz); }),
          _OptTile('📱', 'Send WhatsApp', () { Navigator.pop(context); _sendWhatsApp(invoice); }),
          if (!isPaid)
            _OptTile('✅', 'Mark as Paid', () { Navigator.pop(context); _markPaid(invoice); })
          else
            _OptTile('↩️', 'Mark as Unpaid', () { Navigator.pop(context); _markUnpaid(invoice); },
              color: AppColors.orange),
          _OptTile('🗑️', 'Delete Invoice', () { Navigator.pop(context); _deleteInvoice(invoice); },
            color: AppColors.red),
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
            pw.Text('Place: ${invoice.placeOfSupply}', style: const pw.TextStyle(fontSize: 10)),
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
      'Thank you! 🙏\n\n— Sent via BillZap ⚡');
    final url = Uri.parse('https://wa.me/91$phone?text=$msg');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

// ✅ Edit Invoice Sheet
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
    _custName.dispose(); _custPhone.dispose(); _custGstin.dispose(); _notes.dispose();
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
        Text('Edit Invoice', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800)),
        const Gap(16),
        TextField(controller: _custName,
          decoration: InputDecoration(labelText: 'Customer Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          style: GoogleFonts.dmSans(fontSize: 13.5)),
        const Gap(10),
        Row(children: [
          Expanded(child: TextField(controller: _custPhone, keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: 'Phone',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            style: GoogleFonts.dmSans(fontSize: 13.5))),
          const Gap(10),
          Expanded(child: TextField(controller: _custGstin,
            decoration: InputDecoration(labelText: 'GSTIN',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            style: GoogleFonts.dmSans(fontSize: 13.5))),
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
          style: GoogleFonts.dmSans(fontSize: 13.5)),
        const Gap(16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          child: _saving
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text('Save Changes', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700)))),
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
          const Icon(MaterialSymbols.calendar_today, size: 14, color: AppColors.t3),
          const Gap(6),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.t3)),
            Text(DateFormat('dd MMM yyyy').format(date),
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.t1)),
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
  final Color? color;
  final VoidCallback onTap;
  const _ActionTile(this.emoji, this.title, this.sub,
    {this.loading = false, this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: loading ? AppColors.bg : AppColors.card,
        borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        loading
          ? const SizedBox(width: 28, height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.brand))
          : Text(emoji, style: const TextStyle(fontSize: 22)),
        const Gap(12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14,
            color: color ?? AppColors.t1)),
          Text(sub, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.t3)),
        ])),
        const Icon(MaterialSymbols.chevron_right, color: AppColors.t3),
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
    title: Text(label, style: GoogleFonts.dmSans(
      fontWeight: FontWeight.w700, color: color ?? AppColors.t1)),
    onTap: onTap);
}
