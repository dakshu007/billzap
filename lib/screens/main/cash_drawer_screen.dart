// lib/screens/main/cash_drawer_screen.dart
// "Day Close" — daily cash drawer view replacing the paper notebook habit.
// Shows today's paid invoices broken down by payment mode (Cash / UPI / Bank / Other).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class CashDrawerScreen extends ConsumerStatefulWidget {
  const CashDrawerScreen({super.key});
  @override
  ConsumerState<CashDrawerScreen> createState() => _CashDrawerState();
}

class _CashDrawerState extends ConsumerState<CashDrawerScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _businessDayStart(DateTime.now());
  }

  // Business day starts at 4 AM (so 10pm-2am sales count as "today")
  DateTime _businessDayStart(DateTime now) {
    if (now.hour < 4) {
      // It's after midnight but before 4am → still "yesterday's" business day
      final y = now.subtract(const Duration(days: 1));
      return DateTime(y.year, y.month, y.day, 4, 0);
    }
    return DateTime(now.year, now.month, now.day, 4, 0);
  }

  bool _isSameBusinessDay(DateTime txnTime, DateTime dayStart) {
    final dayEnd = dayStart.add(const Duration(hours: 28)); // 4am to 8am next day
    return !txnTime.isBefore(dayStart) && txnTime.isBefore(dayEnd);
  }

  // Filter invoices to those paid on the selected business day
  List<Invoice> _todaysPaid(List<Invoice> all) {
    return all.where((inv) {
      if (inv.status != InvoiceStatus.paid) return false;
      final paidAt = inv.paidAt ?? inv.invoiceDate;
      return _isSameBusinessDay(paidAt, _selectedDate);
    }).toList();
  }

  List<Expense> _todaysExpenses(List<Expense> all) {
    return all.where((e) => _isSameBusinessDay(e.date, _selectedDate)).toList();
  }

  // Classify invoice by payment mode (stored in notes field as a tag for backward compat)
  // Format: notes may contain "[PAY:cash]", "[PAY:upi]", "[PAY:bank]", "[PAY:other]"
  // Falls back to 'unknown' for old invoices
  String _paymentMode(Invoice inv) {
    final m = RegExp(r'\[PAY:(\w+)\]').firstMatch(inv.notes);
    return m?.group(1) ?? 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    final allInvoices = ref.watch(invoiceProvider);
    final allExpenses = ref.watch(expenseProvider);
    final biz = ref.watch(businessProvider);

    final paid = _todaysPaid(allInvoices);
    final expenses = _todaysExpenses(allExpenses);

    // Group by payment mode
    final byMode = <String, List<Invoice>>{
      'cash': [],
      'upi': [],
      'bank': [],
      'other': [],
      'unknown': [],
    };
    for (final inv in paid) {
      final mode = _paymentMode(inv);
      byMode[mode] ??= [];
      byMode[mode]!.add(inv);
    }

    final cashTotal = byMode['cash']!.fold<double>(0, (s, i) => s + i.grandTotal);
    final upiTotal = byMode['upi']!.fold<double>(0, (s, i) => s + i.grandTotal);
    final bankTotal = byMode['bank']!.fold<double>(0, (s, i) => s + i.grandTotal);
    final otherTotal = byMode['other']!.fold<double>(0, (s, i) => s + i.grandTotal);
    final unknownTotal = byMode['unknown']!.fold<double>(0, (s, i) => s + i.grandTotal);
    final grossTotal = cashTotal + upiTotal + bankTotal + otherTotal + unknownTotal;
    final expenseTotal = expenses.fold<double>(0, (s, e) => s + e.amount);
    final netTotal = grossTotal - expenseTotal;

    final isToday = _isSameBusinessDay(DateTime.now(), _selectedDate);
    final dateLabel = isToday ? 'Today' : DateFormat('EEE, d MMM').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        iconTheme: const IconThemeData(color: AppColors.t1),
        title: Text('Day Close',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.t1)),
        actions: [
          if (paid.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => _shareDaySummary(
                  paid, expenses, biz,
                  cashTotal, upiTotal, bankTotal, otherTotal, unknownTotal,
                  expenseTotal, netTotal),
                icon: const Icon(Symbols.share, size: 18, color: AppColors.brand),
                label: Text('Share',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brand)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
        children: [
          // ─── Date selector ───
          Row(children: [
            IconButton(
              icon: const Icon(Symbols.chevron_left, color: AppColors.t2),
              onPressed: () {
                setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
              },
            ),
            Expanded(child: Center(child: Column(children: [
              Text(dateLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.t1)),
              Text(DateFormat('d MMMM yyyy').format(_selectedDate),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: AppColors.t3)),
            ]))),
            IconButton(
              icon: const Icon(Symbols.chevron_right, color: AppColors.t2),
              onPressed: isToday ? null : () {
                setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
              },
            ),
          ]),
          const Gap(8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _DateChip('Today', isToday, () {
              setState(() => _selectedDate = _businessDayStart(DateTime.now()));
            }),
            const Gap(8),
            _DateChip('Yesterday', _isSameBusinessDay(
              DateTime.now().subtract(const Duration(days: 1)), _selectedDate),
              () {
                setState(() => _selectedDate = _businessDayStart(
                  DateTime.now().subtract(const Duration(days: 1))));
              }),
            const Gap(8),
            _DateChip('Pick', false, () => _pickCustomDate()),
          ]),
          const Gap(20),

          // ─── Hero total card ───
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A1E5E), Color(0xFF1557FF)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TOTAL COLLECTIONS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: Colors.white60, letterSpacing: 0.8)),
              const Gap(6),
              Text(_inrFmt(grossTotal),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
              const Gap(4),
              Text('${paid.length} ${paid.length == 1 ? "invoice" : "invoices"} • '
                   '${expenses.length} ${expenses.length == 1 ? "expense" : "expenses"}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: Colors.white70)),
            ]),
          ),

          if (paid.isEmpty && expenses.isEmpty) ...[
            const Gap(40),
            Center(child: Column(children: [
              const Icon(Symbols.point_of_sale, size: 56, color: AppColors.t4),
              const Gap(12),
              Text('No transactions ${isToday ? "today" : "on this day"} yet',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.t3)),
              const Gap(4),
              Text('Mark invoices as paid to see them here',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: AppColors.t4)),
            ])),
          ] else ...[
            const Gap(20),
            // ─── Payment modes breakdown ───
            Text('PAYMENT MODES',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w800,
                color: AppColors.t3, letterSpacing: 0.8)),
            const Gap(10),
            _ModeRow(
              icon: Symbols.payments,
              iconColor: AppColors.green,
              label: 'Cash',
              count: byMode['cash']!.length,
              amount: cashTotal,
              percent: grossTotal > 0 ? cashTotal / grossTotal : 0,
            ),
            const Gap(8),
            _ModeRow(
              icon: Symbols.qr_code_2,
              iconColor: AppColors.brand,
              label: 'UPI',
              count: byMode['upi']!.length,
              amount: upiTotal,
              percent: grossTotal > 0 ? upiTotal / grossTotal : 0,
            ),
            const Gap(8),
            _ModeRow(
              icon: Symbols.account_balance,
              iconColor: AppColors.purple,
              label: 'Bank Transfer',
              count: byMode['bank']!.length,
              amount: bankTotal,
              percent: grossTotal > 0 ? bankTotal / grossTotal : 0,
            ),
            if (byMode['other']!.isNotEmpty) ...[
              const Gap(8),
              _ModeRow(
                icon: Symbols.receipt,
                iconColor: AppColors.orange,
                label: 'Other',
                count: byMode['other']!.length,
                amount: otherTotal,
                percent: grossTotal > 0 ? otherTotal / grossTotal : 0,
              ),
            ],
            if (byMode['unknown']!.isNotEmpty) ...[
              const Gap(8),
              _ModeRow(
                icon: Symbols.help,
                iconColor: AppColors.t3,
                label: 'Unknown',
                count: byMode['unknown']!.length,
                amount: unknownTotal,
                percent: grossTotal > 0 ? unknownTotal / grossTotal : 0,
              ),
            ],

            // ─── Expenses ───
            if (expenses.isNotEmpty) ...[
              const Gap(20),
              Text('EXPENSES TODAY',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: AppColors.t3, letterSpacing: 0.8)),
              const Gap(10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border)),
                child: Column(children: [
                  for (int i = 0; i < expenses.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(children: [
                        const Icon(Symbols.remove_circle, size: 18, color: AppColors.red),
                        const Gap(10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(expenses[i].title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.t1)),
                            Text(expenses[i].category,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11, color: AppColors.t3)),
                          ])),
                        Text('-${_inrFmt(expenses[i].amount)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.red)),
                      ]),
                    ),
                  ],
                ]),
              ),
            ],

            // ─── Net for the day ───
            const Gap(20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: netTotal >= 0 ? AppColors.greenSoft : AppColors.redSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (netTotal >= 0 ? AppColors.green : AppColors.red).withOpacity(0.3))),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('NET FOR DAY',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: netTotal >= 0 ? AppColors.green : AppColors.red,
                      letterSpacing: 0.8)),
                  const Gap(2),
                  Text('Collections − Expenses',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: AppColors.t3)),
                ]),
                Text(_inrFmt(netTotal),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22, fontWeight: FontWeight.w900,
                    color: netTotal >= 0 ? AppColors.green : AppColors.red)),
              ]),
            ),

            // ─── Detail list of paid invoices ───
            if (paid.isNotEmpty) ...[
              const Gap(20),
              Text('PAID INVOICES',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: AppColors.t3, letterSpacing: 0.8)),
              const Gap(10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border)),
                child: Column(children: [
                  for (int i = 0; i < paid.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(children: [
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: _modeColor(_paymentMode(paid[i])).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8)),
                          child: Icon(_modeIcon(_paymentMode(paid[i])),
                            size: 16, color: _modeColor(_paymentMode(paid[i]))),
                        ),
                        const Gap(10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(paid[i].customerName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
                            Text(paid[i].invoiceNumber,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11, color: AppColors.t3)),
                          ])),
                        Text(_inrFmt(paid[i].grandTotal),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.t1)),
                      ]),
                    ),
                  ],
                ]),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = DateTime(picked.year, picked.month, picked.day, 4, 0));
    }
  }

  // ───────────── Share day summary as text ─────────────
  Future<void> _shareDaySummary(
    List<Invoice> paid, List<Expense> expenses, dynamic biz,
    double cash, double upi, double bank, double other, double unknown,
    double expenseTotal, double net,
  ) async {
    HapticFeedback.lightImpact();
    final bizName = (biz?.name as String?)?.isNotEmpty == true ? biz!.name : 'Business';
    final dateStr = DateFormat('EEE, d MMM yyyy').format(_selectedDate);
    final gross = cash + upi + bank + other + unknown;

    final buf = StringBuffer();
    buf.writeln('🧾 *$bizName — Day Close*');
    buf.writeln('📅 $dateStr');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━');
    buf.writeln();
    buf.writeln('💰 *COLLECTIONS: ${_inrFmt(gross)}*');
    if (cash > 0) buf.writeln('💵 Cash: ${_inrFmt(cash)} (${paid.where((i)=>_paymentMode(i)=="cash").length})');
    if (upi > 0) buf.writeln('📱 UPI: ${_inrFmt(upi)} (${paid.where((i)=>_paymentMode(i)=="upi").length})');
    if (bank > 0) buf.writeln('🏦 Bank: ${_inrFmt(bank)} (${paid.where((i)=>_paymentMode(i)=="bank").length})');
    if (other > 0) buf.writeln('📋 Other: ${_inrFmt(other)} (${paid.where((i)=>_paymentMode(i)=="other").length})');
    if (unknown > 0) buf.writeln('❓ Unknown: ${_inrFmt(unknown)} (${paid.where((i)=>_paymentMode(i)=="unknown").length})');

    if (expenses.isNotEmpty) {
      buf.writeln();
      buf.writeln('💸 *EXPENSES: -${_inrFmt(expenseTotal)}*');
      for (final e in expenses) {
        buf.writeln('• ${e.title}: -${_inrFmt(e.amount)}');
      }
    }

    buf.writeln();
    buf.writeln('━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('✅ *NET FOR DAY: ${_inrFmt(net)}*');
    buf.writeln();
    buf.writeln('Generated by BillZap');

    try {
      await Share.share(buf.toString(), subject: '$bizName Day Close — $dateStr');
    } catch (_) {}
  }

  // ───────────── Helpers ─────────────
  IconData _modeIcon(String mode) {
    switch (mode) {
      case 'cash': return Symbols.payments;
      case 'upi': return Symbols.qr_code_2;
      case 'bank': return Symbols.account_balance;
      case 'other': return Symbols.receipt;
      default: return Symbols.help;
    }
  }

  Color _modeColor(String mode) {
    switch (mode) {
      case 'cash': return AppColors.green;
      case 'upi': return AppColors.brand;
      case 'bank': return AppColors.purple;
      case 'other': return AppColors.orange;
      default: return AppColors.t3;
    }
  }

  String _inrFmt(double v) {
    final isNeg = v < 0;
    final abs = v.abs();
    final parts = abs.toStringAsFixed(0).split('.');
    String integer = parts[0];
    if (integer.length > 3) {
      final last3 = integer.substring(integer.length - 3);
      final rest = integer.substring(0, integer.length - 3);
      final groups = <String>[];
      for (var i = rest.length; i > 0; i -= 2) {
        groups.insert(0, rest.substring(i < 2 ? 0 : i - 2, i));
      }
      integer = '${groups.join(',')},$last3';
    }
    return '${isNeg ? '-' : ''}₹$integer';
  }
}

// ═══════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ═══════════════════════════════════════════════════════════════
class _DateChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DateChip(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : AppColors.bg,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.border)),
        child: Text(label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5, fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.t2)),
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;
  final double amount;
  final double percent;

  const _ModeRow({
    required this.icon, required this.iconColor,
    required this.label, required this.count,
    required this.amount, required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = _inr(amount);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const Gap(11),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.t1)),
              Text('$count ${count == 1 ? "transaction" : "transactions"}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: AppColors.t3)),
            ])),
          Text(fmt,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15, fontWeight: FontWeight.w900, color: iconColor)),
        ]),
        if (percent > 0) ...[
          const Gap(8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 5,
              backgroundColor: AppColors.bg,
              valueColor: AlwaysStoppedAnimation(iconColor),
            ),
          ),
        ],
      ]),
    );
  }

  static String _inr(double v) {
    final isNeg = v < 0;
    final abs = v.abs();
    final parts = abs.toStringAsFixed(0).split('.');
    String integer = parts[0];
    if (integer.length > 3) {
      final last3 = integer.substring(integer.length - 3);
      final rest = integer.substring(0, integer.length - 3);
      final groups = <String>[];
      for (var i = rest.length; i > 0; i -= 2) {
        groups.insert(0, rest.substring(i < 2 ? 0 : i - 2, i));
      }
      integer = '${groups.join(',')},$last3';
    }
    return '${isNeg ? '-' : ''}₹$integer';
  }
}
