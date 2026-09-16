// lib/screens/invoice/invoice_preview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:billzap/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode/barcode.dart' as bc;
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../design/components.dart';
import '../../design/nav_dock.dart';
import '../../design/money.dart';
import '../../design/tokens.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../utils/upi_helper.dart';

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
    final c = isPaid
        ? AppColor.paid
        : invoice.isOverdue
            ? AppColor.overdue
            : AppColor.pending;

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
          // The document scrolls under this bar; without the scrim a row
          // of figures comes out sliced across the title.
          flexibleSpace: const TopScrim(),
          leadingWidth: 62,
          leading: Center(
            child: AppIconButton(
                icon: Symbols.arrow_back,
                size: 40,
                onTap: () => context.go('/invoices')),
          ),
          title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Invoice',
                    style: AppFont.style(AppType.titleM,
                        color: AppColor.textPrimary)),
                Text(invoice.invoiceNumber,
                    style: AppFont.style(AppType.bodyS,
                        color: AppColor.textTertiary)),
              ]),
          actions: [
            if (!isPaid)
              AppIconButton(
                  icon: Symbols.edit,
                  size: 40,
                  onTap: () => _editInvoice(context, invoice)),
            const Gap(AppSpace.sm),
            AppIconButton(
                icon: Symbols.more_vert,
                size: 40,
                onTap: () => _moreOptions(invoice, biz)),
            const Gap(AppSpace.gutter),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter, AppSpace.sm, AppSpace.gutter, 128),
          children: [
            Row(children: [
              StatusPill(
                  invoice.isOverdue ? 'Overdue' : invoice.status.name,
                  tone: c),
            ]),
            const Gap(AppSpace.md),
            _buildDoc(invoice, biz),
            const Gap(AppSpace.md),

            // ═══════════════════════════════════════════════
            // UPI Payment QR card (only shown if not paid)
            // ═══════════════════════════════════════════════
            if (!isPaid) ...[
              _UpiPaymentCard(invoice: invoice, biz: biz),
              const Gap(12),
            ],

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

  /// The invoice document.
  ///
  /// This is the one surface in the app rendered on PAPER rather than on
  /// chrome: a warm off-white, its own ink, and a perforated tear edge at
  /// the foot. That is deliberate — the bill is the artefact the
  /// shopkeeper hands to their customer, and making it read as a physical
  /// receipt rather than another card is what makes a one-person shop
  /// look like a real business.
  Widget _buildDoc(Invoice invoice, Business? biz) {
    final ink = AppColor.docSurface == AppColor.paper
        ? AppColor.paperInk
        : AppColor.textPrimary;
    final inkSoft = ink.withValues(alpha: 0.58);
    final inkFaint = ink.withValues(alpha: 0.38);
    final rule = AppColor.docEdge;

    TextStyle doc(TextStyle base, {Color? color}) =>
        AppFont.style(base, color: color ?? ink);

    return Container(
      decoration: BoxDecoration(
        color: AppColor.docSurface,
        borderRadius: AppRadius.all(AppRadius.lg),
        border: Border.all(color: rule),
        boxShadow: AppElevation.lifted,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Letterhead ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.xl, AppSpace.xl, AppSpace.xl, AppSpace.lg),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(biz?.name ?? 'Your Business',
                      style: doc(AppType.titleM)),
                  if (biz?.gstin.isNotEmpty == true) ...[
                    const Gap(3),
                    Text('GSTIN ${biz!.gstin}',
                        style: doc(AppType.bodyS, color: inkSoft)),
                  ],
                  if (biz?.address.isNotEmpty == true)
                    Text(
                      '${biz!.address}${biz.city.isNotEmpty ? ", ${biz.city}" : ""}',
                      style: doc(AppType.bodyS, color: inkFaint),
                    ),
                ],
              ),
            ),
            const Gap(AppSpace.md),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('TAX INVOICE',
                  style: doc(AppType.overline, color: inkSoft)),
              const Gap(4),
              Text(invoice.invoiceNumber, style: doc(AppType.labelM)),
            ]),
          ]),
        ),
        Divider(height: 1, color: rule),

        // ── Parties and dates ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.xl, AppSpace.lg, AppSpace.xl, AppSpace.lg),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BILLED TO',
                      style: doc(AppType.overline, color: inkFaint)),
                  const Gap(6),
                  Text(invoice.customerName, style: doc(AppType.titleS)),
                  if (invoice.customerPhone.isNotEmpty)
                    Text(invoice.customerPhone,
                        style: doc(AppType.bodyS, color: inkSoft)),
                  if (invoice.customerGstin.isNotEmpty)
                    Text('GSTIN ${invoice.customerGstin}',
                        style: doc(AppType.bodyS, color: inkFaint)),
                ],
              ),
            ),
            const Gap(AppSpace.md),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('ISSUED', style: doc(AppType.overline, color: inkFaint)),
              const Gap(6),
              Text(DateFormat('d MMM yyyy').format(invoice.invoiceDate),
                  style: doc(AppType.labelM)),
              const Gap(8),
              Text('DUE', style: doc(AppType.overline, color: inkFaint)),
              const Gap(6),
              Text(DateFormat('d MMM yyyy').format(invoice.dueDate),
                  style: doc(AppType.labelM,
                      color: invoice.isOverdue ? AppColor.overdue : ink)),
            ]),
          ]),
        ),

        // ── Line items ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
          child: Column(children: [
            Row(children: [
              Expanded(
                  flex: 9,
                  child: Text('ITEM',
                      style: doc(AppType.overline, color: inkFaint))),
              Expanded(
                  flex: 3,
                  child: Padding(
                    padding: _docColGutter,
                    child: Text('QTY',
                        textAlign: TextAlign.right,
                        style: doc(AppType.overline, color: inkFaint)),
                  )),
              Expanded(
                  flex: 5,
                  child: Padding(
                    padding: _docColGutter,
                    child: Text('RATE',
                        textAlign: TextAlign.right,
                        style: doc(AppType.overline, color: inkFaint)),
                  )),
              Expanded(
                  flex: 6,
                  child: Padding(
                    padding: _docColGutter,
                    child: Text('AMOUNT',
                        textAlign: TextAlign.right,
                        style: doc(AppType.overline, color: inkFaint)),
                  )),
            ]),
            const Gap(AppSpace.sm),
            Divider(height: 1, color: rule),
            ...invoice.lineItems.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 9,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: doc(AppType.labelM)),
                              if (item.hsnCode.isNotEmpty)
                                Text('HSN ${item.hsnCode}',
                                    style:
                                        doc(AppType.bodyS, color: inkFaint)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: _docColGutter,
                            child: Text(
                              formatIndianDigits(item.quantity,
                                  decimals: item.quantity ==
                                          item.quantity.roundToDouble()
                                      ? 0
                                      : 2),
                              textAlign: TextAlign.right,
                              style: doc(AppType.numeric, color: inkSoft),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: _docColGutter,
                            child: Money(item.rate,
                                style: AppType.numeric,
                                color: inkSoft,
                                showSymbol: false,
                                compact: false,
                                textAlign: TextAlign.right),
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Padding(
                            padding: _docColGutter,
                            child: Money(item.taxable,
                                style: AppType.amountS,
                                color: ink,
                                showSymbol: false,
                                compact: false,
                                textAlign: TextAlign.right),
                          ),
                        ),
                      ]),
                )),
            Divider(height: 1, color: rule),
            const Gap(AppSpace.md),
          ]),
        ),

        // ── Totals ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
          child: Column(children: [
            _DocTotal('Subtotal', invoice.subtotal, ink, inkSoft),
            if (invoice.totalCgst > 0)
              _DocTotal('CGST ${invoice.gstRateForDisplay / 2}%',
                  invoice.totalCgst, ink, inkSoft),
            if (invoice.totalSgst > 0)
              _DocTotal('SGST ${invoice.gstRateForDisplay / 2}%',
                  invoice.totalSgst, ink, inkSoft),
            if (invoice.totalIgst > 0)
              _DocTotal('IGST ${invoice.gstRateForDisplay}%',
                  invoice.totalIgst, ink, inkSoft),
            if (invoice.shippingCharge > 0)
              _DocTotal('Shipping', invoice.shippingCharge, ink, inkSoft),
            if (invoice.flatDiscount > 0)
              _DocTotal('Discount', -invoice.flatDiscount, ink, inkSoft),
          ]),
        ),
        const Gap(AppSpace.md),

        // ── Grand total. The one figure the customer looks for. ───────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg, vertical: AppSpace.lg),
          decoration: BoxDecoration(
            color: AppColor.wash(AppColor.primary),
            borderRadius: AppRadius.all(AppRadius.md),
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('TOTAL DUE',
                    style: doc(AppType.overline, color: inkSoft)),
                MoneyCounter(invoice.grandTotal,
                    style: AppType.amountL, color: AppColor.paid),
              ]),
        ),

        if (biz != null && (biz.bankName.isNotEmpty || biz.upiId.isNotEmpty)) ...[
          const Gap(AppSpace.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PAY TO', style: doc(AppType.overline, color: inkFaint)),
                const Gap(5),
                if (biz.bankName.isNotEmpty)
                  Text(
                      '${biz.bankName} · A/C ${biz.accountNumber} · IFSC ${biz.ifscCode}',
                      style: doc(AppType.bodyS, color: inkSoft)),
                if (biz.upiId.isNotEmpty)
                  Text('UPI ${biz.upiId}',
                      style: doc(AppType.bodyS, color: inkSoft)),
              ],
            ),
          ),
        ],

        if (invoice.notes.isNotEmpty) ...[
          const Gap(AppSpace.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
            child: Text(invoice.notes,
                style: doc(AppType.bodyS, color: inkSoft)),
          ),
        ],

        const Gap(AppSpace.xl),
        // ── Tear edge ─────────────────────────────────────────────────
        _PerforatedEdge(color: rule),
        Padding(
          padding: const EdgeInsets.only(
              top: AppSpace.md, bottom: AppSpace.lg),
          child: Center(
            child: Text('Generated with BillZap',
                style: doc(AppType.labelS, color: inkFaint)),
          ),
        ),
      ]),
    );
  }

  Widget _buildBottomBar(Invoice invoice, Business? biz) {
    final isPaid = invoice.status == InvoiceStatus.paid;
    return Container(
      padding: EdgeInsets.fromLTRB(14, 12, 14, MediaQuery.of(context).padding.bottom + 12),
      // Theme-aware so the bottom action bar (Paid / Share / PDF) flips
      // with dark mode instead of staying white.
      decoration: BoxDecoration(color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(children: [
        // Mark Paid / Paid badge takes the prime spot when actionable
        if (!isPaid)
          Expanded(child: ElevatedButton.icon(
            onPressed: () => _markPaid(invoice),
            icon: const Icon(Symbols.check_circle, size: 18),
            label: Text('Paid', style: AppFont.sans(fontWeight: FontWeight.w600, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))))
        else
          Expanded(child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.greenSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.green.withOpacity(0.3)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Symbols.check_circle, color: AppColors.green, size: 18),
              const Gap(6),
              Text('Paid',
                style: AppFont.sans(
                  fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.green)),
            ]),
          )),
        const Gap(10),
        Expanded(child: ElevatedButton.icon(
          onPressed: () => _sendWhatsApp(invoice, biz),
          icon: const Icon(Symbols.chat, size: 18),
          label: Text('Share', style: AppFont.sans(fontWeight: FontWeight.w600, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
        const Gap(10),
        Expanded(child: ElevatedButton.icon(
          onPressed: _pdfLoading ? null : () => _downloadPdf(invoice, biz),
          icon: _pdfLoading
            ? SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(
                    color: AppColor.onContrast, strokeWidth: 2))
            : const Icon(Symbols.picture_as_pdf, size: 18),
          label: Text('PDF', style: AppFont.sans(fontWeight: FontWeight.w600, fontSize: 14)),
          // Ink, not jade: Share beside it is WhatsApp green and Paid is
          // a jade outline, so a third green button left the row with no
          // hierarchy at all.
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.contrast,
            foregroundColor: AppColor.onContrast,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
      ]),
    );
  }

  void _moreOptions(Invoice invoice, Business? biz) {
    final isPaid = invoice.status == InvoiceStatus.paid;
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        // Theme-aware: 3-dot options sheet (Edit / Download PDF / Print /
        // WhatsApp / Mark Paid / Delete) now respects dark mode.
        decoration: BoxDecoration(color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
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
            () { Navigator.pop(context); _sendWhatsApp(invoice, biz); }),
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

  // ═══════════════════════════════════════════════════════════
  // PDF GENERATOR — now embeds UPI QR if business has UPI ID
  // ═══════════════════════════════════════════════════════════
  // ════════════════════════════════════════════════════════════════
  // INVOICE PDF
  // ════════════════════════════════════════════════════════════════
  //
  // This is the artefact the shopkeeper's customer actually receives, so
  // it gets the same care as the screen. It mirrors the on-screen paper
  // document: letterhead, ruled sections, a tabular item table, a jade
  // total band, and the UPI QR.
  //
  // Typeface: Inter is embedded rather than using a built-in PDF font.
  // The PDF standard fonts are Latin-1 and have no rupee glyph, which is
  // why this used to print "Rs." — Inter carries U+20B9 and has tabular
  // figures, so printed money columns align the way they do on screen.

  /// Cached across invoices — parsing a 300KB TTF on every share is slow
  /// enough to feel like a hang on a low-end phone.
  static pw.Font? _pdfRegular;
  static pw.Font? _pdfBold;

  static Future<void> _loadPdfFonts() async {
    if (_pdfRegular != null && _pdfBold != null) return;
    _pdfRegular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Inter-Regular.ttf'));
    _pdfBold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Inter-SemiBold.ttf'));
  }

  // The print palette, matched to the app's Ink & Jade tokens. Deliberate
  // constants rather than reads from AppColor: a bill must look the same
  // whether the phone was in dark mode when it was shared or not.
  static const _pInk = PdfColor.fromInt(0xFF0C1014);
  static const _pInkSoft = PdfColor.fromInt(0xFF4C5866);
  static const _pInkFaint = PdfColor.fromInt(0xFF93A0AE);
  static const _pRule = PdfColor.fromInt(0xFFE2E7EC);
  static const _pJade = PdfColor.fromInt(0xFF0A8A5F);
  static const _pJadeWash = PdfColor.fromInt(0xFFEBFAF3);
  static const _pPaper = PdfColor.fromInt(0xFFFBFAF7);

  static Future<pw.Document> buildPdf(Invoice invoice, Business? biz) async {
    await _loadPdfFonts();

    final theme = pw.ThemeData.withFont(
      base: _pdfRegular!,
      bold: _pdfBold!,
    ).copyWith(
      defaultTextStyle: pw.TextStyle(font: _pdfRegular, fontSize: 10, color: _pInk),
    );

    final doc = pw.Document(theme: theme);
    final isPaid = invoice.status == InvoiceStatus.paid;

    /// Indian digit grouping with a real rupee sign.
    String rs(double amount, {bool symbol = true}) {
      final abs = amount.abs();
      final parts = abs.toStringAsFixed(2).split('.');
      var integer = parts[0];
      if (integer.length > 3) {
        final last3 = integer.substring(integer.length - 3);
        final rest = integer.substring(0, integer.length - 3);
        final groups = <String>[];
        for (var i = rest.length; i > 0; i -= 2) {
          groups.insert(0, rest.substring(i < 2 ? 0 : i - 2, i));
        }
        integer = '${groups.join(',')},$last3';
      }
      final sign = amount < 0 ? '-' : '';
      return '$sign${symbol ? '₹' : ''}$integer.${parts[1]}';
    }

    final upiLink = (biz != null &&
            biz.upiId.isNotEmpty &&
            UpiHelper.isValidVpa(biz.upiId) &&
            !isPaid &&
            invoice.grandTotal > 0)
        ? UpiHelper.buildLink(
            vpa: biz.upiId,
            name: biz.name,
            amount: invoice.grandTotal,
            note: invoice.invoiceNumber)
        : null;

    pw.Widget label(String t) => pw.Text(t.toUpperCase(),
        style: pw.TextStyle(
            font: _pdfBold, fontSize: 7, color: _pInkFaint, letterSpacing: 0.8));

    pw.Widget totalRow(String name, double amount, {bool strong = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(name,
                    style: pw.TextStyle(
                        fontSize: 9.5,
                        color: strong ? _pInk : _pInkSoft,
                        font: strong ? _pdfBold : _pdfRegular)),
                pw.Text(rs(amount, symbol: false),
                    style: pw.TextStyle(
                        fontSize: 9.5,
                        font: strong ? _pdfBold : _pdfRegular,
                        color: _pInk)),
              ]),
        );

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(38),
      build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Letterhead ──────────────────────────────────────────
            pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(biz?.name ?? 'Your Business',
                              style: pw.TextStyle(
                                  font: _pdfBold, fontSize: 17, color: _pInk)),
                          if (biz?.gstin.isNotEmpty == true) ...[
                            pw.SizedBox(height: 3),
                            pw.Text('GSTIN ${biz!.gstin}',
                                style: const pw.TextStyle(
                                    fontSize: 9, color: _pInkSoft)),
                          ],
                          if (biz?.address.isNotEmpty == true)
                            pw.Text(
                                '${biz!.address}${biz.city.isNotEmpty ? ", ${biz.city}" : ""}'
                                '${biz.pincode.isNotEmpty ? " ${biz.pincode}" : ""}',
                                style: const pw.TextStyle(
                                    fontSize: 9, color: _pInkFaint)),
                          if (biz?.phone.isNotEmpty == true)
                            pw.Text(biz!.phone,
                                style: const pw.TextStyle(
                                    fontSize: 9, color: _pInkFaint)),
                        ]),
                  ),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        label('Tax Invoice'),
                        pw.SizedBox(height: 4),
                        pw.Text(invoice.invoiceNumber,
                            style: pw.TextStyle(font: _pdfBold, fontSize: 12)),
                        if (isPaid) ...[
                          pw.SizedBox(height: 6),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: const pw.BoxDecoration(
                                color: _pJadeWash,
                                borderRadius:
                                    pw.BorderRadius.all(pw.Radius.circular(3))),
                            child: pw.Text('PAID',
                                style: pw.TextStyle(
                                    font: _pdfBold,
                                    fontSize: 7,
                                    color: _pJade,
                                    letterSpacing: 0.8)),
                          ),
                        ],
                      ]),
                ]),
            pw.SizedBox(height: 16),
            pw.Divider(height: 1, color: _pRule),
            pw.SizedBox(height: 14),

            // ── Parties and dates ───────────────────────────────────
            pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          label('Billed to'),
                          pw.SizedBox(height: 5),
                          pw.Text(invoice.customerName,
                              style:
                                  pw.TextStyle(font: _pdfBold, fontSize: 12)),
                          if (invoice.customerPhone.isNotEmpty)
                            pw.Text(invoice.customerPhone,
                                style: const pw.TextStyle(
                                    fontSize: 9, color: _pInkSoft)),
                          if (invoice.customerGstin.isNotEmpty)
                            pw.Text('GSTIN ${invoice.customerGstin}',
                                style: const pw.TextStyle(
                                    fontSize: 9, color: _pInkFaint)),
                          if (invoice.customerAddress.isNotEmpty)
                            pw.Text(invoice.customerAddress,
                                style: const pw.TextStyle(
                                    fontSize: 9, color: _pInkFaint)),
                        ]),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          label('Issued'),
                          pw.SizedBox(height: 5),
                          pw.Text(
                              DateFormat('d MMM yyyy')
                                  .format(invoice.invoiceDate),
                              style: pw.TextStyle(font: _pdfBold, fontSize: 10)),
                          pw.SizedBox(height: 8),
                          label('Due'),
                          pw.SizedBox(height: 5),
                          pw.Text(
                              DateFormat('d MMM yyyy').format(invoice.dueDate),
                              style: pw.TextStyle(font: _pdfBold, fontSize: 10)),
                          pw.SizedBox(height: 8),
                          label('Place of supply'),
                          pw.SizedBox(height: 5),
                          pw.Text(invoice.placeOfSupply,
                              style: const pw.TextStyle(
                                  fontSize: 9, color: _pInkSoft)),
                        ]),
                  ),
                ]),
            pw.SizedBox(height: 18),

            // ── Items ───────────────────────────────────────────────
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(5),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.4),
                4: const pw.FlexColumnWidth(2.2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                        bottom: pw.BorderSide(color: _pRule, width: 1)),
                  ),
                  children: [
                    _pHead('Item', _pdfBold!),
                    _pHead('Qty', _pdfBold!, right: true),
                    _pHead('Rate', _pdfBold!, right: true),
                    _pHead('GST', _pdfBold!, right: true),
                    _pHead('Amount', _pdfBold!, right: true),
                  ],
                ),
                for (final item in invoice.lineItems)
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(color: _pRule, width: 0.5)),
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 7),
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(item.name,
                                  style: pw.TextStyle(
                                      font: _pdfBold, fontSize: 9.5)),
                              if (item.hsnCode.isNotEmpty)
                                pw.Text('HSN ${item.hsnCode}',
                                    style: const pw.TextStyle(
                                        fontSize: 7.5, color: _pInkFaint)),
                            ]),
                      ),
                      _pCell(
                          item.quantity == item.quantity.roundToDouble()
                              ? item.quantity.toInt().toString()
                              : item.quantity.toString(),
                          right: true),
                      _pCell(rs(item.rate, symbol: false), right: true),
                      _pCell('${item.gstRate.toStringAsFixed(0)}%',
                          right: true),
                      _pCell(rs(item.taxable, symbol: false),
                          right: true, bold: _pdfBold),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 14),

            // ── Totals, right-aligned under the amount column ───────
            pw.Row(children: [
              pw.Spacer(flex: 3),
              pw.Expanded(
                flex: 4,
                child: pw.Column(children: [
                  totalRow('Subtotal', invoice.subtotal),
                  if (invoice.totalCgst > 0)
                    totalRow('CGST ${invoice.gstRateForDisplay / 2}%',
                        invoice.totalCgst),
                  if (invoice.totalSgst > 0)
                    totalRow('SGST ${invoice.gstRateForDisplay / 2}%',
                        invoice.totalSgst),
                  if (invoice.totalIgst > 0)
                    totalRow('IGST ${invoice.gstRateForDisplay}%',
                        invoice.totalIgst),
                  if (invoice.shippingCharge > 0)
                    totalRow('Shipping', invoice.shippingCharge),
                  if (invoice.flatDiscount > 0)
                    totalRow('Discount', -invoice.flatDiscount),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: const pw.BoxDecoration(
                        color: _pJadeWash,
                        borderRadius:
                            pw.BorderRadius.all(pw.Radius.circular(6))),
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(isPaid ? 'TOTAL PAID' : 'TOTAL DUE',
                              style: pw.TextStyle(
                                  font: _pdfBold,
                                  fontSize: 8,
                                  color: _pInkSoft,
                                  letterSpacing: 0.8)),
                          pw.Text(rs(invoice.grandTotal),
                              style: pw.TextStyle(
                                  font: _pdfBold, fontSize: 15, color: _pJade)),
                        ]),
                  ),
                ]),
              ),
            ]),

            // ── Pay by UPI ──────────────────────────────────────────
            if (upiLink != null) ...[
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: _pPaper,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: _pRule, width: 1),
                ),
                child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 84,
                        height: 84,
                        color: PdfColors.white,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.BarcodeWidget(
                            barcode: bc.Barcode.qrCode(),
                            data: upiLink,
                            drawText: false),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Expanded(
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              label('Scan to pay'),
                              pw.SizedBox(height: 5),
                              pw.Text(rs(invoice.grandTotal),
                                  style: pw.TextStyle(
                                      font: _pdfBold,
                                      fontSize: 17,
                                      color: _pInk)),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                  'Opens with the exact amount and reference '
                                  '${invoice.invoiceNumber}.',
                                  style: const pw.TextStyle(
                                      fontSize: 8.5, color: _pInkSoft)),
                              pw.Text(
                                  'Works with GPay, PhonePe, Paytm, BHIM and '
                                  'every other UPI app.',
                                  style: const pw.TextStyle(
                                      fontSize: 8, color: _pInkFaint)),
                            ]),
                      ),
                    ]),
              ),
            ],

            if (biz != null &&
                (biz.bankName.isNotEmpty || biz.upiId.isNotEmpty)) ...[
              pw.SizedBox(height: 16),
              label('Pay to'),
              pw.SizedBox(height: 4),
              if (biz.bankName.isNotEmpty)
                pw.Text(
                    '${biz.bankName}  ·  A/C ${biz.accountNumber}  ·  IFSC ${biz.ifscCode}',
                    style: const pw.TextStyle(fontSize: 9, color: _pInkSoft)),
              if (biz.upiId.isNotEmpty)
                pw.Text('UPI ${biz.upiId}',
                    style: const pw.TextStyle(fontSize: 9, color: _pInkSoft)),
            ],

            if (invoice.notes.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              label('Note'),
              pw.SizedBox(height: 4),
              pw.Text(invoice.notes,
                  style: const pw.TextStyle(fontSize: 9, color: _pInkSoft)),
            ],

            if (invoice.terms.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Text(invoice.terms,
                  style: const pw.TextStyle(fontSize: 8, color: _pInkFaint)),
            ],

            pw.Spacer(),
            pw.Divider(height: 1, color: _pRule),
            pw.SizedBox(height: 8),
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('This is a computer-generated invoice.',
                      style:
                          const pw.TextStyle(fontSize: 7.5, color: _pInkFaint)),
                  pw.Text('Made with BillZap',
                      style:
                          const pw.TextStyle(fontSize: 7.5, color: _pInkFaint)),
                ]),
          ]),
    ));
    return doc;
  }

  static pw.Widget _pHead(String t, pw.Font bold, {bool right = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(t.toUpperCase(),
            textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(
                font: bold, fontSize: 7, color: _pInkFaint, letterSpacing: 0.8)),
      );

  static pw.Widget _pCell(String t,
          {bool right = false, pw.Font? bold}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 7),
        child: pw.Text(t,
            textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(
                fontSize: 9.5, font: bold, color: _pInk)),
      );

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('PDF ready'), backgroundColor: AppColors.green));
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Marked as paid'), backgroundColor: AppColors.green));
  }

  Future<void> _markUnpaid(Invoice invoice) async {
    final ok = await confirm(context,
        title: 'Mark as unpaid?',
        message: 'The status goes back to Sent. Nothing else changes.',
        icon: Symbols.undo,
        tone: AppColor.pending,
        confirmLabel: 'Mark unpaid');
    if (ok) {
      await ref.read(invoiceProvider.notifier).markUnpaid(invoice.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Marked as unpaid'), backgroundColor: AppColors.orange));
    }
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    final ok = await confirm(context,
        title: 'Delete this invoice?',
        message: '${invoice.invoiceNumber} will be removed for good. '
            'This cannot be undone.',
        icon: Symbols.delete,
        destructive: true,
        confirmLabel: 'Delete invoice');
    if (ok) {
      await ref.read(invoiceProvider.notifier).delete(invoice.id);
      if (mounted) context.go('/invoices');
    }
  }

  Future<void> _sendWhatsApp(Invoice invoice, Business? biz) async {
    final isPaid = invoice.status == InvoiceStatus.paid;

    // Build UPI link for payment
    String upiLine = '';
    if (!isPaid &&
        biz != null &&
        biz.upiId.isNotEmpty &&
        UpiHelper.isValidVpa(biz.upiId) &&
        invoice.grandTotal > 0) {
      final link = UpiHelper.buildLink(
        vpa: biz.upiId,
        name: biz.name,
        amount: invoice.grandTotal,
        note: invoice.invoiceNumber);
      upiLine = '\n\n*Pay instantly via UPI:*\n$link';
    }

    final msg = Uri.encodeComponent(
      'Hi ${invoice.customerName},\n\n'
      'Your invoice *${invoice.invoiceNumber}* '
      'for *${formatCurrency(invoice.grandTotal)}* is ready.\n\n'
      'Due: ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}'
      '$upiLine\n\n'
      'Thank you.\n\n— Sent via BillZap');

    final phone = invoice.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');

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
        final fallback = Uri.parse('whatsapp://send?text=$msg');
        if (await canLaunchUrl(fallback)) {
          await launchUrl(fallback, mode: LaunchMode.externalApplication);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('WhatsApp not installed'), backgroundColor: AppColors.red));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red));
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// UPI Payment Card widget
// ═══════════════════════════════════════════════════════════════
class _UpiPaymentCard extends ConsumerWidget {
  final Invoice invoice;
  final Business? biz;
  const _UpiPaymentCard({required this.invoice, this.biz});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Edge case: business has no UPI ID configured yet
    if (biz == null || biz!.upiId.isEmpty) {
      return _NoUpiSetupCard();
    }

    // Edge case: invalid UPI format
    if (!UpiHelper.isValidVpa(biz!.upiId)) {
      return _InvalidUpiCard(vpa: biz!.upiId);
    }

    // Edge case: zero amount
    if (invoice.grandTotal <= 0) {
      return const SizedBox.shrink();
    }

    final upiLink = UpiHelper.buildLink(
      vpa: biz!.upiId,
      name: biz!.name,
      amount: invoice.grandTotal,
      note: invoice.invoiceNumber,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Gradient endpoint reads from theme so the panel flips with dark
        // mode instead of fading into bright white forever.
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brand.withOpacity(
          AppColors.isDark ? 0.45 : 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(12)),
            child: Icon(Symbols.qr_code_2, color: AppColors.onBrand, size: 18),
          ),
          const Gap(10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Pay via UPI',
              style: AppFont.sans(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.t1)),
            Text('Instant payment • All UPI apps',
              style: AppFont.sans(fontSize: 11, color: AppColors.t3)),
          ])),
        ]),
        const Gap(14),
        // QR + amount block
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // QR code — **always** rendered dark-on-white regardless of
          // theme. UPI scanners need high contrast; the previous build
          // used AppColors.t1 (near-white in dark mode), which made the
          // code unscannable. Hardcoded slate-900 + white is the
          // foolproof combo.
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: QrImageView(
              data: upiLink,
              version: QrVersions.auto,
              size: 110,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0F172A)),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0F172A)),
            ),
          ),
          const Gap(14),
          // Right side - amount + actions
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Amount due',
              style: AppFont.sans(
                fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.t3,
                letterSpacing: 0.5)),
            const Gap(2),
            Text(formatCurrency(invoice.grandTotal),
              style: AppFont.sans(
                fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.brand)),
            const Gap(2),
            Text('Ref: ${invoice.invoiceNumber}',
              style: AppFont.sans(fontSize: 10.5, color: AppColors.t3)),
            const Gap(10),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: () => _payNow(context, upiLink),
              icon: const Icon(Symbols.bolt, size: 16),
              label: Text('Pay now',
                style: AppFont.sans(
                  fontSize: 12.5, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: AppColors.onBrand,
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              ),
            )),
          ])),
        ]),
        const Gap(10),
        // Footer with copy link option
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: upiLink));
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('UPI link copied'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              backgroundColor: AppColors.t1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 20),
            ));
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Symbols.content_copy, size: 13, color: AppColors.t3),
              const Gap(6),
              Text('Copy UPI link',
                style: AppFont.sans(
                  fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.t3)),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _payNow(BuildContext context, String upiLink) async {
    HapticFeedback.mediumImpact();
    try {
      final uri = Uri.parse(upiLink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('No UPI app installed'),
            backgroundColor: AppColors.red));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red));
      }
    }
  }
}

// Shown when no UPI ID configured
class _NoUpiSetupCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.yellowSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.yellow.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.yellow.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(Symbols.qr_code_2, color: AppColors.orange, size: 18),
        ),
        const Gap(12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Enable UPI payments',
            style: AppFont.sans(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.t1)),
          Text('Add your UPI ID in Settings to let customers pay instantly via QR.',
            style: AppFont.sans(fontSize: 11.5, color: AppColors.t3)),
        ])),
        const Gap(8),
        ElevatedButton(
          onPressed: () => GoRouter.of(context).go('/settings'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Setup',
            style: AppFont.sans(fontSize: 11.5, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// Shown when UPI ID is malformed
class _InvalidUpiCard extends StatelessWidget {
  final String vpa;
  const _InvalidUpiCard({required this.vpa});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.redSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.red.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(Symbols.error, color: AppColors.red, size: 22),
        const Gap(10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Invalid UPI ID format',
            style: AppFont.sans(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.t1)),
          Text('"$vpa" is not a valid UPI. Should look like name@bank',
            style: AppFont.sans(fontSize: 11.5, color: AppColors.t3)),
        ])),
      ]),
    );
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
      // Theme-aware so the Edit Invoice sheet matches dark mode.
      decoration: BoxDecoration(color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4,
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99))),
        const Gap(14),
        Text('Edit Invoice', style: AppFont.sans(fontSize: 18, fontWeight: FontWeight.w600)),
        const Gap(16),
        TextField(controller: _custName,
          decoration: InputDecoration(labelText: 'Customer Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
          style: AppFont.sans(fontSize: 13.5)),
        const Gap(10),
        Row(children: [
          Expanded(child: TextField(controller: _custPhone, keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: 'Phone',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
            style: AppFont.sans(fontSize: 13.5))),
          const Gap(10),
          Expanded(child: TextField(controller: _custGstin,
            decoration: InputDecoration(labelText: 'GSTIN',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
            style: AppFont.sans(fontSize: 13.5))),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
          style: AppFont.sans(fontSize: 13.5)),
        const Gap(16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          child: _saving
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text('Save Changes', style: AppFont.sans(fontSize: 14, fontWeight: FontWeight.w700)))),
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
          borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(Symbols.calendar_today, size: 14, color: AppColors.t3),
          const Gap(6),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppFont.sans(fontSize: 10, color: AppColors.t3)),
            Text(DateFormat('dd MMM yyyy').format(date),
              style: AppFont.sans(fontSize: 13, color: AppColors.t1)),
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
      ref.read(selectedInvoiceProvider.notifier).select(inv);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Invoice updated'), backgroundColor: AppColors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

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
        borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14)),
          child: loading
            ? Center(child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.brand)))
            : Icon(icon, size: 20, color: iconColor)),
        const Gap(12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppFont.sans(fontWeight: FontWeight.w700, fontSize: 14,
            color: color ?? AppColors.t1)),
          Text(sub, style: AppFont.sans(fontSize: 12, color: AppColors.t3)),
        ])),
        Icon(Symbols.chevron_right, color: AppColors.t3),
      ])));
}

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
        borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 18, color: color)),
    title: Text(label, style: AppFont.sans(
      fontWeight: FontWeight.w700, color: AppColors.t1)),
    onTap: onTap);
}


/// A totals line inside the invoice document.
/// Gutter between the document's numeric columns. Without it a wide
/// amount fills its column edge to edge and runs straight into the rate
/// beside it — "129.0019,350.00" — which is the one thing a tax invoice
/// cannot afford to look like.
const EdgeInsets _docColGutter = EdgeInsets.only(left: AppSpace.sm);

class _DocTotal extends StatelessWidget {
  final String label;
  final double amount;
  final Color ink, inkSoft;
  const _DocTotal(this.label, this.amount, this.ink, this.inkSoft);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: AppFont.style(AppType.bodyM, color: inkSoft)),
          Money(amount,
              style: AppType.amountS,
              color: ink,
              showSymbol: false,
              compact: false),
        ]),
      );
}

/// The torn-off edge at the foot of the bill. Drawn as notches punched out
/// of the paper rather than dots printed on it, so it reads as a physical
/// perforation.
class _PerforatedEdge extends StatelessWidget {
  final Color color;
  const _PerforatedEdge({required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 12,
        child: LayoutBuilder(
          builder: (_, c) {
            const notch = 10.0;
            final count = (c.maxWidth / notch).floor().clamp(1, 200);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                count,
                (_) => Container(
                  width: notch * 0.5,
                  height: notch * 0.5,
                  decoration: BoxDecoration(
                    color: AppColor.canvas,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 0.5),
                  ),
                ),
              ),
            );
          },
        ),
      );
}
