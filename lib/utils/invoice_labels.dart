// lib/utils/invoice_labels.dart — words printed about an invoice.

import '../i18n/translations.dart';
import '../models/models.dart';
import '../tax/active_profile.dart';
import '../tax/profiles.dart';

/// The invoice's status in the language on screen. Overdue wins over
/// the stored status, because that is what the shopkeeper needs to see.
String invoiceStatusLabel(Invoice inv) {
  if (inv.isOverdue) return trGlobal('inv.overdue');
  return switch (inv.status) {
    InvoiceStatus.draft => trGlobal('inv.draft'),
    InvoiceStatus.sent => trGlobal('inv.sent'),
    InvoiceStatus.pending => trGlobal('inv.pending'),
    InvoiceStatus.paid => trGlobal('inv.paid'),
    InvoiceStatus.cancelled => trGlobal('inv.cancelled'),
  };
}

/// What the invoice's own country calls a tax number, an item code and
/// its tax — for the printed document.
///
/// These used to be the literals GSTIN, HSN and GST, so a bill from a
/// shop in Dubai printed "GSTIN" beside its TRN. Read off the invoice
/// rather than the shop's current settings, for the same reason its
/// currency is: a bill reprints as it was issued. For India the three
/// are exactly what they always were.
({String taxId, String itemCode, String tax}) docLabelsFor(Invoice inv) {
  final p = inv.taxCountryCode == activeProfile.countryCode
      ? activeProfile
      : resolveProfile(countryCode: inv.taxCountryCode);
  return (
    taxId: p.taxIdLabel,
    itemCode: p.itemCodeLabel ?? 'Item code',
    tax: p.taxName,
  );
}
