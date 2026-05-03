// lib/screens/festival/festival_greeting_screen.dart
// Batch festival greeting flow:
// 1. Select customers (default: those billed in last 90 days)
// 2. Preview/edit message
// 3. Send via WhatsApp one by one (semi-automated since WhatsApp doesn't support bulk API)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../utils/festival_data.dart';
import '../../i18n/translations.dart';

class FestivalGreetingScreen extends ConsumerStatefulWidget {
  final String festivalId;
  const FestivalGreetingScreen({super.key, required this.festivalId});

  @override
  ConsumerState<FestivalGreetingScreen> createState() => _FestivalGreetingState();
}

class _FestivalGreetingState extends ConsumerState<FestivalGreetingScreen> {
  late TextEditingController _messageCtrl;
  final Set<String> _selectedIds = {};
  int _currentSendIndex = -1; // -1 = not sending. >=0 = currently on this index

  @override
  void initState() {
    super.initState();
    _messageCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initMessage());
  }

  void _initMessage() {
    final festival = FestivalData.byId(widget.festivalId);
    if (festival == null) return;

    final biz = ref.read(businessProvider);
    final bizName = (biz?.name as String?)?.isNotEmpty == true ? biz!.name : 'Your Business';

    // Get user's app language
    final lang = ref.read(languageProvider);
    final msg = festival.messageFor(lang).replaceAll('{biz}', bizName);
    _messageCtrl.text = msg;

    // Pre-select customers billed in last 90 days
    final invoices = ref.read(invoiceProvider);
    final recent = DateTime.now().subtract(const Duration(days: 90));
    final activeNames = <String>{};
    for (final inv in invoices) {
      if (inv.invoiceDate.isAfter(recent)) {
        activeNames.add(inv.customerName);
      }
    }

    final customers = ref.read(customerProvider);
    setState(() {
      for (final c in customers) {
        if (c.phone.isNotEmpty &&
            (activeNames.contains(c.name) || activeNames.isEmpty && customers.length <= 30)) {
          _selectedIds.add(c.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  // ───── WhatsApp send ─────
  Future<void> _sendOne(Customer c) async {
    final phone = _normalizePhone(c.phone);
    if (phone.isEmpty) return;
    final msg = _messageCtrl.text.trim();
    final encoded = Uri.encodeComponent(msg);
    final url = Uri.parse('https://wa.me/$phone?text=$encoded');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  String _normalizePhone(String raw) {
    var p = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (p.length == 10) {
      return '91$p'; // assume India
    } else if (p.length == 12 && p.startsWith('91')) {
      return p;
    } else if (p.length == 11 && p.startsWith('0')) {
      return '91${p.substring(1)}';
    }
    return p;
  }

  Future<void> _startBulkSend() async {
    final selectedCustomers = ref.read(customerProvider)
      .where((c) => _selectedIds.contains(c.id) && c.phone.isNotEmpty)
      .toList();

    if (selectedCustomers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Select at least one customer with a phone number'),
        backgroundColor: AppColors.red));
      return;
    }

    // Confirm before sending
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Send greetings?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('This will open WhatsApp ${selectedCustomers.length} times.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13)),
          const Gap(8),
          Text('After each Send, return to this app — the next customer will open automatically.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5, color: AppColors.t3)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand, foregroundColor: Colors.white),
            child: Text('Start (${selectedCustomers.length})')),
        ],
      ),
    );
    if (confirmed != true) return;

    // Begin send loop
    setState(() => _currentSendIndex = 0);
    for (int i = 0; i < selectedCustomers.length; i++) {
      if (!mounted) return;
      setState(() => _currentSendIndex = i);
      await _sendOne(selectedCustomers[i]);
      // Small delay between sends so user can interact with WhatsApp
      await Future.delayed(const Duration(milliseconds: 800));
    }

    if (!mounted) return;
    setState(() => _currentSendIndex = -1);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Symbols.check_circle, color: AppColors.green),
          SizedBox(width: 10),
          Text('All sent!'),
        ]),
        content: Text(
          'Greetings opened in WhatsApp for all ${selectedCustomers.length} customers. '
          'You\'re all set! 🎉'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK')),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final festival = FestivalData.byId(widget.festivalId);
    if (festival == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Festival not found')),
        body: const Center(child: Text('This festival is no longer available.')),
      );
    }

    final allCustomers = ref.watch(customerProvider);
    final withPhone = allCustomers.where((c) => c.phone.isNotEmpty).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final withoutPhone = allCustomers.where((c) => c.phone.isEmpty).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        iconTheme: const IconThemeData(color: AppColors.t1),
        title: Row(children: [
          Text(festival.emoji, style: const TextStyle(fontSize: 22)),
          const Gap(8),
          Text(festival.name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.t1)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
        children: [
          // ─── Festival hero card ───
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6F00), Color(0xFFFFB300)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Text(festival.emoji, style: const TextStyle(fontSize: 36)),
              const Gap(12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(festival.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                Text(_formatDate(festival.date),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: Colors.white.withOpacity(0.92))),
                if (festival.isToday) ...[
                  const Gap(4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(99)),
                    child: Text('TODAY',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: 0.7)),
                  ),
                ],
              ])),
            ]),
          ),
          const Gap(20),

          // ─── Message section ───
          Text('MESSAGE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w800,
              color: AppColors.t3, letterSpacing: 0.8)),
          const Gap(8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border)),
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _messageCtrl,
              maxLines: 6,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Your message...',
              ),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5, color: AppColors.t1, height: 1.5),
            ),
          ),
          const Gap(6),
          Text('You can edit this message before sending',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11, color: AppColors.t3, fontStyle: FontStyle.italic)),
          const Gap(20),

          // ─── Customer selection ───
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('SEND TO',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w800,
                color: AppColors.t3, letterSpacing: 0.8)),
            Row(children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedIds.clear();
                    for (final c in withPhone) { _selectedIds.add(c.id); }
                  });
                },
                child: Text('Select all',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.brand)),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedIds.clear()),
                child: Text('Clear',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.t3)),
              ),
            ]),
          ]),
          const Gap(4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(10)),
            child: Text(
              '${_selectedIds.length} of ${withPhone.length} customers selected'
              '${withoutPhone > 0 ? " • $withoutPhone without phone skipped" : ""}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brand)),
          ),
          const Gap(10),

          if (withPhone.isEmpty) ...[
            const Gap(20),
            Center(child: Column(children: [
              const Icon(Symbols.person_off, size: 48, color: AppColors.t4),
              const Gap(8),
              Text('No customers with phone numbers',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.t3)),
              const Gap(4),
              Text('Add phone numbers to your customers to use this feature',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5, color: AppColors.t4)),
            ])),
          ] else
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border)),
              child: Column(children: [
                for (int i = 0; i < withPhone.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  CheckboxListTile(
                    value: _selectedIds.contains(withPhone[i].id),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedIds.add(withPhone[i].id);
                        } else {
                          _selectedIds.remove(withPhone[i].id);
                        }
                      });
                    },
                    activeColor: AppColors.brand,
                    title: Text(withPhone[i].name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.t1)),
                    subtitle: Text(withPhone[i].phone,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5, color: AppColors.t3)),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ],
              ]),
            ),

          const Gap(20),

          // ─── Send button ───
          if (_currentSendIndex >= 0)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.yellowSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.yellow.withOpacity(0.4))),
              child: Row(children: [
                const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2,
                    color: AppColors.orange)),
                const Gap(10),
                Expanded(child: Text(
                  'Sending ${_currentSendIndex + 1} of ${_selectedIds.length}...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1))),
              ]),
            )
          else
            ElevatedButton.icon(
              onPressed: _selectedIds.isEmpty || withPhone.isEmpty
                  ? null : _startBulkSend,
              icon: const Icon(Symbols.send, size: 18),
              label: Text(
                _selectedIds.isEmpty
                  ? 'Select customers'
                  : 'Send to ${_selectedIds.length} customer${_selectedIds.length == 1 ? "" : "s"}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

          const Gap(12),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Symbols.info, size: 14, color: AppColors.t3),
              const Gap(8),
              Expanded(child: Text(
                'WhatsApp will open one customer at a time. Tap Send in WhatsApp, then return — the next will open automatically.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: AppColors.t3, height: 1.45))),
            ]),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}
