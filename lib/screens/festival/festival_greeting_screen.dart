// lib/screens/festival/festival_greeting_screen.dart
// Batch festival greeting flow:
// 1. Select customers (default: those billed in last 90 days)
// 2. Preview/edit message
// 3. Send via WhatsApp one by one (semi-automated since WhatsApp doesn't support bulk API)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:billzap/theme/app_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../i18n/dates.dart';
import '../../utils/festival_data.dart';
import '../../utils/phone_number.dart';
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
    final bizName = biz?.name.isNotEmpty == true ? biz!.name : trGlobal('set.your_business');

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
    if (c.phone.trim().isEmpty) return;
    final phone = whatsAppNumber(c.phone,
        shopCountry: ref.read(businessProvider)?.countryCode ?? 'IN');
    final msg = _messageCtrl.text.trim();
    final encoded = Uri.encodeComponent(msg);
    // No number we can be sure of: WhatsApp asks which contact.
    final url = phone == null
        ? Uri.parse('https://wa.me/?text=$encoded')
        : Uri.parse('https://wa.me/$phone?text=$encoded');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _startBulkSend() async {
    final selectedCustomers = ref.read(customerProvider)
      .where((c) => _selectedIds.contains(c.id) && c.phone.isNotEmpty)
      .toList();

    if (selectedCustomers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(trGlobal('fest.select_one')),
        backgroundColor: AppColors.red));
      return;
    }

    // Confirm before sending
    final confirmed = await confirm(context,
        title: trGlobal('fest.send_q'),
        message: trGlobal('fest.send_q_msg', {'n': selectedCustomers.length}),
        icon: Symbols.send,
        confirmLabel: trGlobal('fest.start', {'n': selectedCustomers.length}),
        cancelLabel: trGlobal('common.cancel'));
    if (!confirmed) return;

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
    notify(context,
        title: trGlobal('fest.all_sent'),
        message: trGlobal('fest.all_sent_msg', {'n': selectedCustomers.length}),
        icon: Symbols.check_circle,
        tone: AppColor.paid);
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final festival = FestivalData.byId(widget.festivalId);
    if (festival == null) {
      return Scaffold(
        appBar: AppBar(title: Text(trGlobal('fest.not_found'))),
        body: Center(child: Text(trGlobal('fest.not_found_msg'))),
      );
    }

    final allCustomers = ref.watch(customerProvider);
    final withPhone = allCustomers.where((c) => c.phone.isNotEmpty).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final withoutPhone = allCustomers.where((c) => c.phone.isEmpty).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        iconTheme: IconThemeData(color: AppColors.t1),
        title: Row(children: [
          Icon(festival.icon, size: 22, color: AppColors.orange),
          const Gap(8),
          Text(festival.name,
            style: AppFont.sans(
              fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.t1)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
        children: [
          // ─── Festival hero card ───
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Icon(festival.icon, size: 36, color: AppColors.orange),
              const Gap(12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(festival.name,
                  style: AppFont.sans(
                    fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                Text(_formatDate(festival.date),
                  style: AppFont.sans(
                    fontSize: 12, color: Colors.white.withOpacity(0.92))),
                if (festival.isToday) ...[
                  const Gap(4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(99)),
                    child: Text(trGlobal('fest.today').toUpperCase(),
                      style: AppFont.sans(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        color: Colors.white, letterSpacing: 0.7)),
                  ),
                ],
              ])),
            ]),
          ),
          const Gap(20),

          // ─── Message section ───
          Text(trGlobal('fest.message').toUpperCase(),
            style: AppFont.sans(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: AppColors.t3, letterSpacing: 0.8)),
          const Gap(8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border)),
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _messageCtrl,
              maxLines: 6,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: trGlobal('fest.message_hint'),
              ),
              style: AppFont.sans(
                fontSize: 13.5, color: AppColors.t1, height: 1.5),
            ),
          ),
          const Gap(6),
          Text(trGlobal('fest.editable'),
            style: AppFont.sans(
              fontSize: 11, color: AppColors.t3, fontStyle: FontStyle.italic)),
          const Gap(20),

          // ─── Customer selection ───
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(trGlobal('fest.send_to').toUpperCase(),
              style: AppFont.sans(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColors.t3, letterSpacing: 0.8)),
            Row(children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedIds.clear();
                    for (final c in withPhone) { _selectedIds.add(c.id); }
                  });
                },
                child: Text(trGlobal('fest.select_all'),
                  style: AppFont.sans(
                    fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.brand)),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedIds.clear()),
                child: Text(trGlobal('inv.clear_filters'),
                  style: AppFont.sans(
                    fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.t3)),
              ),
            ]),
          ]),
          const Gap(4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(14)),
            child: Text(
              trGlobal('fest.selected', {'a': _selectedIds.length, 'b': withPhone.length}) +
              (withoutPhone > 0 ? trGlobal('fest.skipped', {'n': withoutPhone}) : ''),
              style: AppFont.sans(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brand)),
          ),
          const Gap(10),

          if (withPhone.isEmpty) ...[
            const Gap(20),
            Center(child: Column(children: [
              Icon(Symbols.person_off, size: 48, color: AppColors.t4),
              const Gap(8),
              Text(trGlobal('fest.no_phones'),
                style: AppFont.sans(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.t3)),
              const Gap(4),
              Text(trGlobal('fest.no_phones_sub'),
                textAlign: TextAlign.center,
                style: AppFont.sans(
                  fontSize: 11.5, color: AppColors.t4)),
            ])),
          ] else
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
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
                      style: AppFont.sans(
                        fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.t1)),
                    subtitle: Text(withPhone[i].phone,
                      style: AppFont.sans(
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
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.yellow.withOpacity(0.4))),
              child: Row(children: [
                SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2,
                    color: AppColors.orange)),
                const Gap(10),
                Expanded(child: Text(
                  trGlobal('fest.sending', {'a': _currentSendIndex + 1, 'b': _selectedIds.length}),
                  style: AppFont.sans(
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
                  ? trGlobal('fest.select_customers')
                  : trCount('fest.send_n', _selectedIds.length),
                style: AppFont.sans(
                  fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

          const Gap(12),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Symbols.info, size: 14, color: AppColors.t3),
              const Gap(8),
              Expanded(child: Text(
                trGlobal('fest.how'),
                style: AppFont.sans(
                  fontSize: 11, color: AppColors.t3, height: 1.45))),
            ]),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => uiDate('d MMMM y', d);
}
