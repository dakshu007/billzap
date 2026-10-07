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

/// Whether a UPI payment request belongs on this invoice.
///
/// UPI is India's payment system: it moves rupees between Indian bank
/// accounts and nothing else. A shop billing in lek or dirhams that put
/// a UPI QR on its bill would be asking the customer to pay the bill's
/// number in rupees — the screenshot that found this showed "₹46.02"
/// under a L46.02 invoice. Converting is not an answer either: an
/// offline app has no exchange rate it could stand behind, and the
/// customer still could not pay without an Indian account. So: rupee
/// invoices only. Read off the invoice, not the shop, because a bill
/// keeps the currency it was issued in.
bool upiApplies(Invoice inv) => inv.taxCountryCode.toUpperCase() == 'IN';

/// What the bank routing code is called on the printed bill: IFSC in
/// India, a neutral word everywhere else, where the same field holds a
/// SWIFT/BIC, sort code or routing number.
String bankCodeLabel(Invoice inv) => upiApplies(inv) ? 'IFSC' : 'Bank code';
