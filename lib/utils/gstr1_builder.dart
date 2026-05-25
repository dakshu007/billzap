// lib/utils/gstr1_builder.dart
//
// Generates a GSTR-1 compatible JSON document from the local invoice
// store. The output follows the public GSTR-1 offline-utility schema
// (`gstin`, `fp`, `gt`, `b2b`, `b2cs`, `hsn` sections) — the same shape
// CAs can drop into the GST portal's offline tool.
//
// Caveats kept intentionally simple for the v1:
//   • B2B is determined by presence of a 15-char customer GSTIN.
//   • B2CS is everything else, aggregated by GST-rate × place-of-supply.
//   • HSN summary aggregates per-HSN-per-rate quantities & taxable value.
//   • Place-of-supply uses the state code from the business profile when
//     the line is intra-state, or the GSTIN's first 2 digits for B2B.
//
// This is *not* a substitute for a CA-grade tool — but for the typical
// small-shop user it saves a ton of typing into the offline utility.

import 'dart:convert';
import '../models/models.dart';

class Gstr1Builder {
  /// Builds a JSON string in the GSTR-1 offline-utility shape.
  /// `from` / `to` define the return period. `biz` is the business
  /// whose GSTIN files the return.
  static String build({
    required List<Invoice> invoices,
    required DateTime from,
    required DateTime to,
    required Business? biz,
  }) {
    // Period in MMYYYY format ("042026" for April 2026).
    final fp = '${from.month.toString().padLeft(2, '0')}${from.year}';
    final ownGstin = biz?.gstin.trim().toUpperCase() ?? '';
    final ownStateCode = biz?.stateCode.trim() ??
        (ownGstin.length >= 2 ? ownGstin.substring(0, 2) : '33');

    final filtered = invoices.where((i) =>
        i.status != InvoiceStatus.cancelled &&
        !i.invoiceDate.isBefore(_dayStart(from)) &&
        !i.invoiceDate.isAfter(_dayEnd(to))).toList();

    // ── B2B ────────────────────────────────────────────────────────
    // Group by customer GSTIN.
    final b2bByCtin = <String, List<Invoice>>{};
    final b2cs = <Invoice>[];
    for (final inv in filtered) {
      final ctin = inv.customerGstin.trim().toUpperCase();
      if (ctin.length == 15) {
        b2bByCtin.putIfAbsent(ctin, () => []).add(inv);
      } else {
        b2cs.add(inv);
      }
    }

    final b2bList = b2bByCtin.entries.map((entry) {
      final ctin = entry.key;
      return {
        'ctin': ctin,
        'inv': entry.value.map((inv) => _invoiceBlock(inv, ownStateCode)).toList(),
      };
    }).toList();

    // ── B2CS ──────────────────────────────────────────────────────
    // Aggregated by (place-of-supply, rate, supply-type).
    final b2csMap = <String, Map<String, dynamic>>{};
    for (final inv in b2cs) {
      final pos = _posFor(inv, ownStateCode);
      final rate = inv.gstRateForDisplay;
      final sply = (pos == ownStateCode) ? 'INTRA' : 'INTER';
      final key = '$pos|$rate|$sply';
      final agg = b2csMap.putIfAbsent(key, () => {
        'sply_ty': sply,
        'pos': pos,
        'rt': rate,
        'typ': 'OE',  // Other (Exempt covered separately if needed)
        'txval': 0.0,
        'iamt': 0.0,
        'camt': 0.0,
        'samt': 0.0,
        'csamt': 0.0,
      });
      agg['txval'] = (agg['txval'] as double) + inv.subtotal;
      agg['iamt']  = (agg['iamt']  as double) + inv.totalIgst;
      agg['camt']  = (agg['camt']  as double) + inv.totalCgst;
      agg['samt']  = (agg['samt']  as double) + inv.totalSgst;
    }

    // ── HSN summary ───────────────────────────────────────────────
    // Per (hsn, rate) — sum qty + taxable + tax components.
    final hsnMap = <String, Map<String, dynamic>>{};
    var hsnSerial = 1;
    for (final inv in filtered) {
      for (final li in inv.lineItems) {
        final hsn = li.hsnCode.trim().isEmpty ? '0' : li.hsnCode.trim();
        final rate = li.gstRate;
        final key = '$hsn|$rate';
        final agg = hsnMap.putIfAbsent(key, () => {
          'num': hsnSerial++,
          'hsn_sc': hsn,
          'desc': li.name,
          'uqc': _uqcFor(li.unit),
          'qty': 0.0,
          'rt': rate,
          'txval': 0.0,
          'iamt': 0.0,
          'camt': 0.0,
          'samt': 0.0,
          'csamt': 0.0,
        });
        agg['qty']   = (agg['qty']   as double) + li.quantity;
        final taxable = li.taxable;
        agg['txval'] = (agg['txval'] as double) + taxable;
        // Split tax between IGST vs CGST+SGST based on the invoice the
        // line came from.
        if (inv.totalIgst > 0) {
          agg['iamt'] = (agg['iamt'] as double) + (taxable * rate / 100);
        } else {
          agg['camt'] = (agg['camt'] as double) + (taxable * rate / 200);
          agg['samt'] = (agg['samt'] as double) + (taxable * rate / 200);
        }
      }
    }

    // ── Grand total (gt = aggregate turnover) ─────────────────────
    final gt = filtered.fold<double>(0, (s, i) => s + i.grandTotal);

    final out = <String, dynamic>{
      'gstin': ownGstin,
      'fp': fp,
      'gt': _round2(gt),
      'cur_gt': _round2(gt),
      'b2b': b2bList,
      'b2cs': b2csMap.values.map((m) => {
        ...m,
        'txval': _round2(m['txval'] as double),
        'iamt':  _round2(m['iamt']  as double),
        'camt':  _round2(m['camt']  as double),
        'samt':  _round2(m['samt']  as double),
      }).toList(),
      'hsn': {
        'data': hsnMap.values.map((m) => {
          ...m,
          'qty':   _round2(m['qty']   as double),
          'txval': _round2(m['txval'] as double),
          'iamt':  _round2(m['iamt']  as double),
          'camt':  _round2(m['camt']  as double),
          'samt':  _round2(m['samt']  as double),
        }).toList(),
      },
    };

    return const JsonEncoder.withIndent('  ').convert(out);
  }

  static Map<String, dynamic> _invoiceBlock(Invoice inv, String ownStateCode) {
    final ctin = inv.customerGstin.trim().toUpperCase();
    final pos = ctin.length >= 2 ? ctin.substring(0, 2) : ownStateCode;
    final isIntra = pos == ownStateCode;
    return {
      'inum': inv.invoiceNumber,
      'idt': _ddMMyyyy(inv.invoiceDate),
      'val': _round2(inv.grandTotal),
      'pos': pos,
      'rchrg': 'N',
      'inv_typ': 'R',
      'itms': inv.lineItems.map((li) {
        final taxable = li.taxable;
        final rate = li.gstRate;
        final itm = <String, dynamic>{
          'num': inv.lineItems.indexOf(li) + 1,
          'itm_det': {
            'rt': rate,
            'txval': _round2(taxable),
            if (!isIntra) 'iamt': _round2(taxable * rate / 100),
            if (isIntra)  'camt': _round2(taxable * rate / 200),
            if (isIntra)  'samt': _round2(taxable * rate / 200),
            'csamt': 0,
          },
        };
        return itm;
      }).toList(),
    };
  }

  static String _posFor(Invoice inv, String ownStateCode) {
    // For B2CS the place of supply is the customer's state. We don't
    // store it explicitly so fall back to own-state.
    return ownStateCode;
  }

  // Best-effort mapping from our free-text "Nos / kg / lt" units onto
  // the GSTN UQC codes. Defaults to OTH for anything unrecognised.
  static String _uqcFor(String unit) {
    final u = unit.trim().toLowerCase();
    const map = {
      'nos': 'NOS-NUMBERS', 'no': 'NOS-NUMBERS', 'pcs': 'PCS-PIECES',
      'kg': 'KGS-KILOGRAMS', 'kgs': 'KGS-KILOGRAMS',
      'g': 'GMS-GRAMMES', 'gm': 'GMS-GRAMMES', 'gms': 'GMS-GRAMMES',
      'lt': 'LTR-LITRE', 'ltr': 'LTR-LITRE', 'l': 'LTR-LITRE',
      'ml': 'MLT-MILLILITRE',
      'mt': 'MTS-METRES', 'm': 'MTS-METRES',
      'box': 'BOX-BOX', 'pkt': 'PAC-PACKS', 'pack': 'PAC-PACKS',
      'set': 'SET-SETS', 'pair': 'PRS-PAIRS', 'doz': 'DOZ-DOZEN',
    };
    return map[u] ?? 'OTH-OTHERS';
  }

  static double _round2(double v) =>
      (v * 100).roundToDouble() / 100;

  static String _ddMMyyyy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-${d.year}';

  static DateTime _dayStart(DateTime d) =>
      DateTime(d.year, d.month, d.day);
  static DateTime _dayEnd(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59);
}
