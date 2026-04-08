// lib/screens/main/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invs = ref.watch(invoiceProvider);
    final exps = ref.watch(expenseProvider);
    final now  = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    final last6months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - 5 + i);
      return [d.month, d.year, months[d.month - 1]];
    });

    final vals = last6months.map((l) => invs
      .where((i) => i.status == InvoiceStatus.paid &&
        i.invoiceDate.month == (l[0] as int) && i.invoiceDate.year == (l[1] as int))
      .fold<double>(0, (s, i) => s + i.grandTotal)).toList();

    final maxV = vals.isEmpty ? 1.0 : vals.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);

    final paidInvs = invs.where((i) => i.status == InvoiceStatus.paid);
    final cgst = paidInvs.fold<double>(0, (s, i) => s + i.totalCgst);
    final sgst = paidInvs.fold<double>(0, (s, i) => s + i.totalSgst);
    final igst = paidInvs.fold<double>(0, (s, i) => s + i.totalIgst);
    final rev  = paidInvs.fold<double>(0, (s, i) => s + i.grandTotal);
    final expTot = exps.fold<double>(0, (s, e) => s + e.amount);

    // Top customers
    final custMap = <String, double>{};
    for (final i in paidInvs) {
      custMap[i.customerName] = (custMap[i.customerName] ?? 0) + i.grandTotal;
    }
    final topCusts = custMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false, backgroundColor: AppColors.card,
        title: Text('Reports', style: GoogleFonts.nunito(
          fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        children: [
          // Revenue chart
          _Card('Monthly Revenue', child: Column(children: [
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(6, (i) {
                  return Expanded(child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: (vals[i] / maxV * 110).clamp(4.0, 110.0),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: i == 5 ? AppColors.brand : AppColors.brandSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const Gap(5),
                      Text(
                        last6months[i][2] as String,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: i == 5 ? FontWeight.w700 : FontWeight.w500,
                          color: i == 5 ? AppColors.brand : AppColors.t3,
                        ),
                      ),
                    ],
                  ));
                }),
              ),
            ),
          ])),
          const Gap(12),

          // GST summary
          _Card('GST Summary (All Paid Invoices)', child: Column(children: [
            Row(children: [
              _GBox('CGST', cgst, AppColors.brand, AppColors.brandSoft),
              const Gap(8),
              _GBox('SGST', sgst, AppColors.orange, AppColors.orangeSoft),
              const Gap(8),
              _GBox('IGST', igst, AppColors.t3, AppColors.bg),
            ]),
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: AppColors.yellowSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.yellow.withOpacity(0.3))),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Total GST Payable', style: GoogleFonts.dmSans(
                  fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.t1)),
                Text(formatCurrency(cgst + sgst + igst), style: GoogleFonts.nunito(
                  fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.t1)),
              ])),
          ])),
          const Gap(12),

          // P&L
          _Card('Profit & Loss', child: Column(children: [
            _PLRow('Total Revenue', rev, AppColors.green),
            _PLRow('Total Expenses', expTot, AppColors.red),
            const Divider(height: 20),
            _PLRow('Net Profit / Loss', rev - expTot,
              rev - expTot >= 0 ? AppColors.green : AppColors.red, bold: true),
          ])),
          const Gap(12),

          // Invoice status
          _Card('Invoice Status', child: Column(children: [
            _statusRow(invs, InvoiceStatus.paid, 'Paid', AppColors.green),
            _statusRow(invs, InvoiceStatus.sent, 'Sent', AppColors.brand),
            _statusRow(invs, InvoiceStatus.pending, 'Pending', AppColors.yellow),
            // Overdue
            Builder(builder: (_) {
              final ov = invs.where((i) => i.isOverdue).length;
              return Row(children: [
                SizedBox(width: 72, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.redSoft,
                    borderRadius: BorderRadius.circular(99)),
                  child: Text('Overdue', style: GoogleFonts.dmSans(
                    fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.red)))),
                const Gap(10),
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: invs.isEmpty ? 0 : ov / invs.length,
                    backgroundColor: AppColors.bg, minHeight: 8,
                    valueColor: const AlwaysStoppedAnimation(AppColors.red)))),
                const Gap(10),
                SizedBox(width: 24, child: Text('$ov',
                  style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.t1),
                  textAlign: TextAlign.right)),
              ]);
            }),
          ])),
          const Gap(12),

          // Top customers
          if (topCusts.isNotEmpty)
            _Card('Top Customers', child: Builder(builder: (context) {
              final maxVal = topCusts.first.value;
              return Column(children: topCusts.take(5).map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  Container(width: 32, height: 32,
                    decoration: BoxDecoration(color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(
                      e.key.isNotEmpty ? e.key[0].toUpperCase() : '?',
                      style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.brand)))),
                  const Gap(10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.key, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
                    const Gap(3),
                    ClipRRect(borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: maxVal > 0 ? (e.value / maxVal).clamp(0.0, 1.0) : 0,
                        backgroundColor: AppColors.bg, minHeight: 5,
                        valueColor: const AlwaysStoppedAnimation(AppColors.brand))),
                  ])),
                  const Gap(10),
                  Text(formatCurrency(e.value), style: GoogleFonts.nunito(
                    fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.t1)),
                ]))).toList());
            })),
        ],
      ),
    );
  }
}


Widget _statusRow(List<Invoice> invs, InvoiceStatus status, String label, Color color) {
  final cnt = invs.where((i) => i.status == status && !i.isOverdue).length;
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      SizedBox(width: 72, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(99)),
        child: Text(label, style: GoogleFonts.dmSans(
          fontSize: 11.5, fontWeight: FontWeight.w700, color: color)))),
      const Gap(10),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: invs.isEmpty ? 0 : cnt / invs.length,
          backgroundColor: AppColors.bg, minHeight: 8,
          valueColor: AlwaysStoppedAnimation(color)))),
      const Gap(10),
      SizedBox(width: 24, child: Text('$cnt',
        style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.t1),
        textAlign: TextAlign.right)),
    ]));
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card(this.title, {required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.card,
      borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.nunito(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.t1)),
      const Gap(14),
      child,
    ]),
  );
}

class _GBox extends StatelessWidget {
  final String label; final double value; final Color color, soft;
  const _GBox(this.label, this.value, this.color, this.soft);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Text(label, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      const Gap(4),
      Text(formatCurrency(value), style: GoogleFonts.nunito(
        fontSize: 13, fontWeight: FontWeight.w900, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
    ])));
}

class _PLRow extends StatelessWidget {
  final String label; final double value; final Color color; final bool bold;
  const _PLRow(this.label, this.value, this.color, {this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.dmSans(fontSize: 13.5,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: AppColors.t1)),
      Text(formatCurrency(value), style: GoogleFonts.nunito(
        fontSize: bold ? 17 : 14, fontWeight: FontWeight.w800, color: color)),
    ]));
}
