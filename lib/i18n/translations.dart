// lib/i18n/translations.dart — every string the app shows, and lookup.
//
// HOW IT IS LAID OUT
//
// English lives here, in Dart, as the source of truth and the floor
// every lookup falls back to. It is compiled in, so the app can always
// show something on the first frame and the tests can read it without
// an asset bundle.
//
// Every other language is a JSON file in assets/i18n/<id>.json, keyed
// exactly as below, loaded when it is chosen. 126 languages compiled
// into the binary would cost every user memory for 125 they never read.
// The list of languages and which countries they are offered in is
// lib/i18n/locales.dart.
//
// TO ADD A STRING
//
//   1. Add the key and its English here.
//   2. Use it: tr('key', ref) in a ConsumerWidget, trGlobal('key')
//      anywhere else. Values can take {name} arguments:
//      trGlobal('inv.count', {'n': 3}).
//   3. Translate it into the JSON files. A file missing a key is not a
//      crash — the English shows — and test/i18n_assets_test.dart lists
//      exactly which files are missing what.
//
// WHAT IS NOT TRANSLATED, ON PURPOSE
//
// The invoice itself — the PDF, and the on-screen preview of it, which
// shows exactly what the PDF will contain — and the CSV and GSTR-1
// exports. Those are documents that leave the phone for a customer, an
// accountant or a tax authority. Their embedded font covers Latin only,
// the PDF engine cannot shape Indic or Arabic script, and a machine-
// translated label on a tax document is a risk no shopkeeper signed up
// for. The app's own screens are translated; the paperwork stays in the
// language the tax authority reads.

import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../design/money.dart' show activeCurrencySymbol;
import '../tax/active_profile.dart';
import '../tax/countries.dart';
import 'locales.dart';

export 'locales.dart' show AppLocale, kAppLocales, appLocaleFor;

// ── English (base) ────────────────────────────────────────────
const _en = <String, String>{
  // Voice billing.
  // This key was referenced by voice_invoice_screen.dart and never
  // defined, so trGlobal fell through to returning the key and the
  // snackbar showed the user the literal text 'voice.not_available'.
  // i18n_keys_test.dart now fails the build if that happens again.
  'voice.not_available': 'Voice billing is not available on this device',

  // Country / tax setup. The last two are deliberately plain about
  // what the app does and does not know, because the difference
  // decides whether the shopkeeper can trust the rate on their bill.
  'set.country': 'Country & tax',
  'set.tax_verified':
      'Tax rules for this country are built into the app.',
  'set.tax_custom':
      'No built-in rules for this country, so you set the rate. '
      'Please confirm it with your tax authority.',
  'set.tax_unconfirmed':
      'Standard rate as of October 2026, from a global tax reference. '
      'It does not account for reduced rates or exemptions on what you '
      'sell — confirm it with your tax authority.',
  'set.tax_edit': 'Tax rate',
  'set.tax_name': 'What the tax is called',
  'set.tax_rate': 'Rate',
  'set.save': 'Save',

  'onboard.country_title': 'Where do you trade?',
  'onboard.country_sub':
      'This sets your currency and how tax is worked out on every bill.',
  'onboard.country_known':
      'Tax rules for this country are built in — rates, the tax split '
      'and the right name for your tax number.',
  'onboard.country_custom':
      'No built-in tax rules for this country yet, so you set the rate '
      'and what it is called. Check it against your tax authority.',

  // Navigation
  'nav.home': 'Home',
  'nav.invoices': 'Invoices',
  'nav.reports': 'Reports',
  'nav.me': 'Me',
  'nav.create': 'Create',
  'nav.customers': 'Customers',
  'nav.products': 'Products',
  'nav.expenses': 'Expenses',
  'nav.settings': 'Settings',

  // Dashboard
  'dash.greeting_morning': 'Good morning',
  'dash.greeting_afternoon': 'Good afternoon',
  'dash.greeting_evening': 'Good evening',
  'dash.this_month': 'This Month',
  'dash.outstanding': 'Outstanding',
  'dash.recent_invoices': 'Recent Invoices',
  'dash.quick_actions': 'Quick Actions',
  'dash.new_invoice': 'New Invoice',
  'dash.see_all': 'See all',
  'dash.no_invoices': 'No invoices yet',
  'dash.create_first': 'Create your first invoice',

  // Invoices
  'inv.title': 'Invoices',
  'inv.search': 'Search invoices',
  'inv.all': 'All',
  'inv.paid': 'Paid',
  'inv.unpaid': 'Unpaid',
  'inv.draft': 'Draft',
  'inv.invoice_no': 'Invoice No.',
  'inv.customer': 'Customer',
  'inv.amount': 'Amount',
  'inv.date': 'Date',
  'inv.status': 'Status',
  'inv.due_date': 'Due Date',
  'inv.subtotal': 'Subtotal',
  'inv.tax': 'Tax',
  'inv.cgst': 'CGST',
  'inv.sgst': 'SGST',
  'inv.igst': 'IGST',
  'inv.total': 'Total',
  'inv.grand_total': 'Grand Total',
  'inv.notes': 'Notes',
  'inv.terms': 'Terms & Conditions',

  // Create Invoice
  'create.title': 'New Invoice',
  'create.select_customer': 'Select Customer',
  'create.add_customer': 'Add New Customer',
  'create.add_item': 'Add Item',
  'create.item_name': 'Item Name',
  'create.quantity': 'Qty',
  'create.rate': 'Rate',
  'create.hsn': 'HSN/SAC',
  'create.discount': 'Discount',
  'create.preview': 'Preview',
  'create.save_send': 'Save & Send',
  'create.save_draft': 'Save Draft',
  'create.share_whatsapp': 'Share on WhatsApp',
  'create.share_pdf': 'Share PDF',

  // Customers
  'cust.title': 'Customers',
  'create.customer': 'Customer',
  'cust.add_new': 'Add Customer',
  'cust.name': 'Name',
  'cust.phone': 'Phone',
  'cust.gstin': '{taxid}',
  'cust.address': 'Address',
  'cust.email': 'Email',
  'cust.no_customers': 'No customers yet',
  'cust.required': 'Customer name is required',

  // Products
  'prod.title': 'Products',
  'prod.add_new': 'Add Product',
  'prod.name': 'Product Name',
  'prod.price': 'Price',
  'prod.unit': 'Unit',
  'prod.no_products': 'No products yet',
  'prod.required': 'Product name is required',

  // Expenses
  'exp.title': 'Expenses',
  'exp.add_new': 'Add Expense',
  'exp.expense_title': 'Title',
  'exp.amount': 'Amount',
  'exp.category': 'Category',
  'exp.date': 'Date',
  'exp.no_expenses': 'No expenses yet',
  'exp.cat_rent': 'Rent',
  'exp.cat_salary': 'Salary',
  'exp.cat_utilities': 'Utilities',
  'exp.cat_travel': 'Travel',
  'exp.cat_food': 'Food',
  'exp.cat_marketing': 'Marketing',
  'exp.cat_equipment': 'Equipment',
  'exp.cat_other': 'Other',

  // Reports
  'rep.title': 'Reports',
  'rep.revenue': 'Revenue',
  'rep.expenses': 'Expenses',
  'rep.profit': 'Profit',
  'rep.this_month': 'This Month',
  'rep.last_month': 'Last Month',
  'rep.this_year': 'This Year',
  'rep.gst_summary': '{tax} Summary',
  'rep.export_csv': 'Export CSV',

  // Settings
  'set.title': 'Settings',
  'set.business': 'Business',
  'set.bank': 'Bank & UPI',
  'set.invoice': 'Invoice',
  'set.about': 'About',
  'set.language': 'Language',
  'set.choose_language': 'Choose your language',
  'set.business_profile': 'Business Profile',
  'set.business_name': 'Business Name',
  'set.bank_details': 'Bank Details',
  'set.bank_name': 'Bank Name',
  'set.account_number': 'Account Number',
  'set.ifsc': 'IFSC Code',
  'set.upi_id': 'UPI ID',
  'set.invoice_prefix': 'Invoice Prefix',
  'set.default_terms': 'Default Terms',
  'set.version': 'Version',
  'set.offline': '100% Offline',
  'set.privacy': 'Privacy',
  'set.price': 'Price',
  'set.always_free': 'Always free',
  'set.data_on_device': 'Data stays on device',
  'set.no_internet': 'No internet needed',

  // Common
  'common.save': 'Save',
  'common.cancel': 'Cancel',
  'common.delete': 'Delete',
  'common.edit': 'Edit',
  'common.share': 'Share',
  'common.print': 'Print',
  'common.back': 'Back',
  'common.next': 'Next',
  'common.done': 'Done',
  'common.ok': 'OK',
  'common.yes': 'Yes',
  'common.no': 'No',
  'common.error': 'Error',
  'common.success': 'Success',
  'common.saved': 'Saved',
  'common.deleted': 'Deleted',
  'common.required': 'Required',
  'common.optional': 'Optional',
  'common.search': 'Search',
  'common.loading': 'Loading...',

  // Splash & Onboarding
  'splash.tagline': 'Free {tax} billing, offline',

  // Toast & messages
  'toast.exit_again': 'Press back again to exit',
  'msg.whatsapp_not_installed': 'WhatsApp not installed',
  'msg.invoice_created': 'Invoice created successfully',
  'msg.invoice_deleted': 'Invoice deleted',
  'msg.customer_added': 'Customer added',
  'msg.product_added': 'Product added',
  'cat.title': 'Catalog',
  'cat.empty': 'Your catalog is empty',
  'cat.empty_hint': 'Add items here to quickly use them in invoices.\n{tax} is auto-detected from item name.',
  'cat.add_first': 'Add First Item',
  'cat.add_title': 'Add to Catalog',
  'cat.gst_auto_hint': '{tax} is auto-detected from item name',
  'cat.item_name': 'Item Name *',
  'cat.item_hint': 'e.g. Apple, Mobile, Soap',
  'cat.price': 'Price ({currency}) *',
  'cat.unit': 'Unit',
  'cat.hsn': '{itemcode} Code (optional)',
  'cat.save': 'Save to Catalog',
  'cat.delete_title': 'Delete from catalog?',
  'cat.from_catalog': 'From Catalog',
  'onboard.welcome': 'Welcome to BillZap',
  'onboard.welcome_sub': 'Free {tax} billing for your business — no signup, no internet, no fees.',
  'onboard.skip': 'Skip',
  'onboard.feat_fast': 'Lightning fast',
  'onboard.feat_fast_sub': 'Create invoices in seconds',
  'onboard.feat_offline': '100% offline',
  'onboard.feat_offline_sub': 'Works without internet',
  'onboard.feat_private': 'Your data, your phone',
  'onboard.feat_private_sub': 'Nothing sent to any server',
  'onboard.feat_free': 'Always free',
  'onboard.feat_free_sub': 'No subscriptions ever',
  'onboard.profile_title': 'Set up your business',
  'onboard.profile_sub': 'This appears on your invoices. You can change it anytime in Settings.',
  'onboard.business_name': 'Business name *',
  'onboard.phone': 'Phone',
  'onboard.gstin_optional': '{taxid} (optional)',
  'onboard.address': 'Address',
  'onboard.city': 'City',
  'onboard.state': 'State',
  'onboard.edit_later_hint': 'You can edit these anytime in Settings.',
  'onboard.business_required': 'Business name is required',
  'onboard.done_title': 'You\'re all set!',
  'onboard.done_sub': 'Start creating professional {tax} invoices for your customers.',
  'onboard.get_started': 'Get started',
  'inv.sent': 'Sent',
  'inv.pending': 'Pending',
  'inv.overdue': 'Overdue',
  'inv.due': 'Due',
  'inv.no_results': 'No results found',
  'inv.try_diff_search': 'Try a different search',
  'inv.tap_plus_create': 'Tap + to create one',
  'inv.cancelled': 'Cancelled',
  'inv.clear_filters': 'Clear',
  'inv.swipe_delete_hint': 'Swipe left to delete',
  'set.change': 'Change',
  'set.about_billzap': 'About BillZap',
  'set.save_business': 'Save Business Profile',
  'set.save_bank': 'Save Bank Details',
  'set.save_settings': 'Save Settings',
  'set.city': 'City',
  'set.pincode': 'Pincode',
  'set.state': 'State',
  'set.invoice_settings': 'Invoice Settings',
  'dash.greeting_night': 'Good night',
  'dash.setup_profile': 'Set up your business profile',
  'dash.total_revenue': 'Total revenue',
  'dash.revenue': 'Revenue',
  'dash.pending': 'Pending',
  'dash.gst_collected': '{tax} Collected',
  'dash.this_month_label': 'this month',
  'dash.auto_calc': 'Auto-calculated',
  'cust.tap_add': 'Tap + to add your first customer',
  'cust.inv_short': 'inv',
  'rep.monthly_revenue': 'Monthly Revenue',
  'rep.total_gst_payable': 'Total {tax} Payable',
  'rep.profit_loss': 'Profit & Loss',
  'rep.total_revenue': 'Total Revenue',
  'rep.total_expenses': 'Total Expenses',
  'rep.net_profit': 'Net Profit / Loss',
  'rep.invoice_status': 'Invoice Status',
  'rep.top_customers': 'Top Customers',
  'create.search_customer': 'Search or type customer name...',
  'create.optional': 'optional',
  'create.invoice_details': 'Invoice Details',
  'create.invoice_date': 'Invoice Date',
  'create.due_date': 'Due Date',
  'create.place_of_supply': 'Place of Supply',
  'create.line_items': 'Line Items',
  'create.add_line_item': 'Add Line Item',
  'create.tax_adjustments': 'Tax & Adjustments',
  'create.apply_gst': 'Apply {tax}',
  'create.gst_auto_calc': 'CGST / SGST / IGST auto-calculated',
  'create.gst_type': '{tax} Type',
  'create.cgst_sgst': 'CGST + SGST (Intra-state)',
  'create.igst': 'IGST (Inter-state)',
  'create.apply_discount': 'Apply Discount',
  'create.flat_discount': 'Flat discount on subtotal',
  'create.add_shipping': 'Add Shipping',
  'create.delivery_charges': 'Delivery / freight charges',
  'create.shipping': 'Shipping',
  'create.summary': 'Summary',
  'create.subtotal': 'Subtotal',
  'create.grand_total': 'Grand Total',
  'create.notes': 'Notes',
  'create.notes_hint': 'Additional notes for customer...',
  'create.cust_required': 'Customer name is required',
  'create.add_item_required': 'Add at least one item',
  'create.catalog_empty': 'No items in catalog. Add items first from Home → Catalog.',
  // App Lock + Theme + Backup + Website (added round 4)
  'set.app_lock':            'App Lock',
  'set.lock_hint':           'Lock app with PIN or fingerprint',
  'set.lock_enabled':        'Enabled',
  'set.lock_pin_only':       'PIN only',
  'set.lock_pin_fp':         'PIN + Fingerprint',
  'set.lock_disable_title':  'Disable App Lock?',
  'set.lock_disable_msg':    'Your data will no longer require a PIN to access.',
  'set.lock_disable_btn':    'Disable',
  'set.theme':               'Theme',
  'set.theme_light':         'Light',
  'set.theme_dark':          'Dark',
  'set.theme_system':        'System default',
  'set.theme_choose':        'Choose theme',
  'set.theme_light_sub':     'Always bright',
  'set.theme_dark_sub':      'Easy on the eyes • saves battery',
  'set.theme_system_sub':    'Match phone setting',
  'set.backup_export':       'Backup & Export',
  'set.backup_export_sub':   'Save your data • Export CSVs for accountant',
  'set.visit_website':       'Visit our website',
  'set.visit_website_sub':   'Get help, learn more, share feedback',
  'set.visit_site_btn':      'Visit our website',
  'dash.day_close':          'Day Close',
  'dash.day_close_sub':      "Today's collections by Cash, UPI, Bank",
  'dash.voice_bill':         'Voice Bill',
  'dash.voice_bill_sub':     'Speak to create invoices in your language',
  // Refer friends + stock + GSTR-1 (round 5)
  'set.refer_friend':      'Refer a friend',
  'set.refer_friend_sub':  'Tell shop owners about BillZap',
  'dash.stock_alert':      'Stock alert',
  'prod.edit':             'Edit Product',
  'prod.cost':             'Cost (optional)',
  'prod.margin':           'Margin',
  'prod.track_stock':      'Track stock',
  'prod.stock_on_hand':    'Stock on hand',
  'prod.low_alert_at':     'Low-stock alert at',
  'prod.out_of_stock':     'Out',
  'rep.gstr1_json':        'GSTR-1 JSON',

  // ── Added for the worldwide build ─────────────────────────────
  // Every string that used to be hardcoded English in a screen, a
  // dialog, a snackbar or a validator. Grouped by screen.
  // Keys ending .one/.other are counts, read with trCount().
  // bk
  'bk.all_invoices': 'All Invoices',
  'bk.all_invoices_sub': '{n} invoices with the full {tax} breakdown',
  'bk.backup_all': 'Backup all data',
  'bk.backup_now': 'Backup now',
  'bk.choose_file': 'Choose file',
  'bk.choose_pin': 'Choose a PIN',
  'bk.counts': '{i} invoices • {c} customers • {e} expenses',
  'bk.created': 'Backup created • {file}',
  'bk.creating': 'Creating backup...',
  'bk.enter_pin': 'Enter backup PIN',
  'bk.enter_pin_label': 'Enter PIN',
  'bk.enter_pin_msg': 'Enter the 4-digit PIN you set when creating this backup.',
  'bk.err_invalid': 'Invalid backup file',
  'bk.err_newer': 'Backup created with a newer app version. Update BillZap and try again.',
  'bk.err_not_found': 'File not found',
  'bk.err_pin_short': 'PIN must be at least 4 digits',
  'bk.err_wrong_pin': 'Wrong PIN or corrupted backup file',
  'bk.expenses_sub': '{n} expense records',
  'bk.export_failed': 'Export failed: {e}',
  'bk.export_header': 'Export for accountant (CSV)',
  'bk.exported': 'Exported • {file}',
  'bk.failed': 'Backup failed',
  'bk.ledger': 'Customer Ledger',
  'bk.ledger_sub': '{n} customers with billing totals',
  'bk.no_access': 'Could not access selected file',
  'bk.no_customers': 'No customers to export',
  'bk.no_expenses': 'No expenses to export',
  'bk.no_invoices': 'No invoices to export',
  'bk.picker_failed': 'File picker failed: {e}',
  'bk.pin_mismatch': 'The two PINs are different',
  'bk.pin_short': 'A PIN needs at least 4 digits',
  'bk.protect': 'Protect your data',
  'bk.replace': 'Replace my data',
  'bk.restore_done': 'Restore complete',
  'bk.restore_failed': 'Restore failed',
  'bk.restore_q': 'Restore this backup?',
  'bk.restore_q_msg': 'Everything on this phone is replaced by what is in the backup file. Anything not in the file is lost.',
  'bk.restore_sub': 'Import a previously saved backup file',
  'bk.restore_title': 'Restore from backup',
  'bk.restoring': 'Restoring...',
  'bk.set_pin': 'Set backup PIN',
  'bk.set_pin_msg': 'Choose a 4-digit PIN to protect this backup. You\'ll need it to restore.',
  'bk.share_failed': 'Share failed: {e}',
  'bk.share_subject': 'BillZap Backup',
  'bk.share_text': 'BillZap backup saved on {date}.\n\nKeep this file safe — you\'ll need your PIN to restore it.',
  'bk.subj_customers': 'BillZap Customers',
  'bk.subj_expenses': 'BillZap Expenses',
  'bk.subj_invoices': 'BillZap Invoices',
  'bk.subj_summary': 'BillZap {tax} Summary',
  'bk.summary_sub': 'Month-wise totals for your accountant',
  'bk.summary_sub_in': 'Ready for GSTR-1 filing — month-wise totals',
  'bk.summary_title': '{tax} Summary (Monthly)',
  'bk.tip': 'Backup files are PIN-protected. Send them to yourself via WhatsApp / Email / Drive for safekeeping.',
  'bk.type_again': 'Type it again',
  // cat
  'cat.code_generic': 'Item code',
  'cat.delete_msg': '{name} will be removed from your catalogue.',
  // common
  'common.added_named': '{name} added',
  'common.beta': 'Beta',
  'common.confirm': 'Confirm',
  'common.continue': 'Continue',
  'common.delete_q': 'Delete {name}?',
  'common.deleted_named': '{name} deleted',
  'common.error_detail': 'Error: {e}',
  'common.save_changes': 'Save Changes',
  'common.updated_named': '{name} updated',
  // cp
  'cp.all_countries': 'All countries',
  'cp.built_in': 'tax rules built in',
  'cp.count.one': '{n} country',
  'cp.count.other': '{n} countries',
  'cp.no_match': 'No country matches "{q}".\nTry the currency code instead — AED, KES, BRL.',
  'cp.prefilled': 'rate offered — confirm it',
  'cp.rates_checked': 'Rates checked',
  'cp.search_hint': 'Country, currency or code',
  'cp.you_set': 'you set the tax rate',
  'cp.your_country': 'Your country',
  // create
  'create.address_hint': 'Street, area, city',
  'create.customer_helper': 'Start typing to pull up a saved customer',
  'create.customer_sub': 'Who this bill is for',
  'create.details_sub': 'Dates, and the place that sets the tax split',
  'create.item_hint': 'Product or service',
  'create.items.one': '{n} item',
  'create.items.other': '{n} items',
  'create.lines.one': '{n} line on this bill',
  'create.lines.other': '{n} lines on this bill',
  'create.notes_sub': 'Prints at the foot of the bill',
  'create.place_hint': 'City, region or province',
  'create.place_other': 'Other state · IGST',
  'create.place_same': 'Same state · CGST + SGST',
  'create.place_sheet_sub': 'Sets the tax split on this bill',
  'create.place_where': 'Where the supply happened',
  'create.search_states': 'Search states',
  'create.state_code': 'State code {code}',
  'create.summary_sub': 'What the customer pays',
  'create.tax_sub': '{tax}, discount and delivery',
  // cust
  'cust.delete_msg': 'Their invoices stay in the ledger — only the saved contact goes.',
  // dash
  'dash.bills.one': '{n} bill',
  'dash.bills.other': '{n} bills',
  'dash.low.one': '{n} item running low',
  'dash.low.other': '{n} items running low',
  'dash.out.one': '{n} item out of stock',
  'dash.out.other': '{n} items out of stock',
  'dash.out_and_low': '{out} out of stock · {low} running low',
  'dash.unpaid_n': '{n} unpaid',
  // dc
  'dc.bank': 'Bank Transfer',
  'dc.bank_short': 'Bank',
  'dc.business': 'Business',
  'dc.cash': 'Cash',
  'dc.collections': 'Collections',
  'dc.expenses': 'Expenses',
  'dc.expenses.one': '{n} expense',
  'dc.expenses.other': '{n} expenses',
  'dc.expenses_today': 'Expenses today',
  'dc.generated': 'Generated by BillZap',
  'dc.invoices.one': '{n} invoice',
  'dc.invoices.other': '{n} invoices',
  'dc.modes': 'Payment modes',
  'dc.net': 'Net for day',
  'dc.net_sub': 'Collections − Expenses',
  'dc.none_day': 'No transactions on this day yet',
  'dc.none_hint': 'Mark invoices as paid to see them here',
  'dc.none_today': 'No transactions today yet',
  'dc.other': 'Other',
  'dc.paid_invoices': 'Paid invoices',
  'dc.pick': 'Pick',
  'dc.today': 'Today',
  'dc.total': 'Total collections',
  'dc.txn.one': '{n} transaction',
  'dc.txn.other': '{n} transactions',
  'dc.unknown': 'Unknown',
  'dc.upi': 'UPI',
  'dc.yesterday': 'Yesterday',
  // ex
  'ex.all_time': 'All Time',
  'ex.custom': 'Custom',
  'ex.exported': 'Exported {file}',
  'ex.failed': 'Export failed: {e}',
  'ex.gstr1_failed': 'GSTR-1 export failed: {e}',
  'ex.gstr1_ready': 'GSTR-1 JSON ready',
  'ex.period': 'Period',
  'ex.pl_sub': 'Revenue − Expenses with category breakdown',
  'ex.present': 'Present',
  'ex.reports': 'Reports',
  'ex.revenue_sub': 'Earnings, top customers, month-wise breakdown',
  'ex.status_sub': 'Paid / Pending / Overdue + aging analysis',
  'ex.subject': 'BillZap Report',
  'ex.tax_sub': 'Tax collected and payable, period by period',
  'ex.tax_sub_in': 'CGST/SGST/IGST breakdown for GSTR-1 filing',
  'ex.this_quarter': 'This Quarter',
  'ex.tip': 'PDFs are great for sharing and printing. CSVs work in Excel for further analysis.',
  'ex.title': 'Export Reports',
  // exp
  'exp.delete_msg': 'This expense comes straight out of your profit figure, so removing it changes your reports.',
  'exp.total': 'Total',
  // fest
  'fest.all_sent': 'All sent',
  'fest.all_sent_msg': 'Greetings opened in WhatsApp for all {n} customers.',
  'fest.banner_sub': 'Send greetings to your customers in one tap',
  'fest.editable': 'You can edit this message before sending',
  'fest.how': 'WhatsApp will open one customer at a time. Tap Send in WhatsApp, then return — the next will open automatically.',
  'fest.is_today': 'It\'s {name} today!',
  'fest.is_tomorrow': '{name} is tomorrow',
  'fest.message': 'Message',
  'fest.message_hint': 'Your message...',
  'fest.no_phones': 'No customers with phone numbers',
  'fest.no_phones_sub': 'Add phone numbers to your customers to use this feature',
  'fest.not_found': 'Festival not found',
  'fest.not_found_msg': 'This festival is no longer available.',
  'fest.select_all': 'Select all',
  'fest.select_customers': 'Select customers',
  'fest.select_one': 'Select at least one customer with a phone number',
  'fest.selected': '{a} of {b} customers selected',
  'fest.send_n.one': 'Send to {n} customer',
  'fest.send_n.other': 'Send to {n} customers',
  'fest.send_q': 'Send greetings?',
  'fest.send_q_msg': 'WhatsApp opens {n} times — once per customer. Come back to BillZap after each Send and the next one opens on its own.',
  'fest.send_to': 'Send to',
  'fest.sending': 'Sending {a} of {b}...',
  'fest.skipped': ' • {n} without phone skipped',
  'fest.start': 'Start ({n})',
  'fest.today': 'Today',
  // fp
  'fp.choose': 'Choose backup file',
  'fp.continue': 'Continue to BillZap',
  'fp.done': 'PIN reset successfully!',
  'fp.done_sub': 'You can now use your new PIN.',
  'fp.forgot': 'Forgot PIN?',
  'fp.intro': 'No problem. To reset your PIN, you\'ll need your BillZap backup file (ends with .billzap).',
  'fp.invalid_file': 'This file is not a valid BillZap backup.',
  'fp.new_pin': 'Set a new 4-digit PIN',
  'fp.read_error': 'Error reading file: {e}',
  'fp.title': 'Reset PIN',
  'fp.validating': 'Validating...',
  'fp.verified': 'Backup verified',
  'fp.where': 'Where to find it',
  'fp.where_downloads': 'Downloads folder on this phone',
  'fp.where_email': 'Email attachments',
  'fp.where_whatsapp': 'WhatsApp media (if you sent it)',
  // ins
  'ins.ahead_msg': 'Invoices due this week: {n}, worth {amount}.',
  'ins.ahead_title': 'Week ahead',
  'ins.biz_msg': 'Invoices paid: {n}, {amount} earned overall. Keep going!',
  'ins.biz_title': 'Your business',
  'ins.busy_msg': '{day} is your best sales day this month — {amount} earned.',
  'ins.busy_title': 'Busiest day',
  'ins.clear_msg': 'No overdue invoices. Great cash flow!',
  'ins.clear_title': 'All clear',
  'ins.create_invoice': 'Create invoice',
  'ins.follow_msg': 'You haven\'t billed {name} in {n} days. Reach out?',
  'ins.follow_title': 'Time to follow up',
  'ins.overdue_msg': 'Overdue invoices: {n}, worth {amount}. Time to follow up.',
  'ins.overdue_title': 'Overdue',
  'ins.record_msg': 'You earned {amount} this week — your best week yet!',
  'ins.record_title': 'New record',
  'ins.send_thanks': 'Send thanks',
  'ins.start_msg': 'Create your first invoice in seconds. Tap the + button or use Voice Bill.',
  'ins.start_title': 'Get started',
  'ins.tax_msg': '{amount} {tax} collected in {month} so far. File on time to avoid penalties.',
  'ins.tax_title': '{tax} collected',
  'ins.thanks_msg': 'Thank you so much for your continued business this month.\nIt means a lot. Looking forward to serving you again soon.',
  'ins.top_msg': '{name} is your top customer this month — {amount} across multiple invoices.',
  'ins.top_title': 'Top customer',
  'ins.view_invoices': 'View invoices',
  'ins.view_overdue': 'View overdue',
  'ins.view_report': 'View report',
  'ins.wa_unavailable': 'WhatsApp not available',
  'ins.week_down': '{amount} this week — down {pct}% from last week. Push harder!',
  'ins.week_first': 'You earned {amount} this week. Keep it up!',
  'ins.week_steady': '{amount} earned this week — steady performance',
  'ins.week_title': 'This week',
  'ins.week_up': '{amount} this week — up {pct}% from last week',
  'ins.welcome': 'Welcome to BillZap! Create your first invoice to see insights here.',
  // inv
  'inv.bills.one': '{n} bill',
  'inv.bills.other': '{n} bills',
  'inv.deleted_named': '{no} deleted',
  'inv.due_on': 'Due {date}',
  'inv.total_count': '{n} total',
  // lang
  'lang.all_languages': 'All languages',
  'lang.apply': 'Apply',
  'lang.apply_named': 'Use {lang}',
  'lang.beta_note': 'Machine-translated and not yet checked by a native speaker. Some words may be wrong.',
  'lang.country': 'Country',
  'lang.country_hint': 'Only filters this list. Your shop\'s country and tax stay as they are.',
  'lang.in_use': 'in use',
  'lang.language': 'Language',
  'lang.no_match': 'No language matches "{q}".',
  'lang.search': 'Search languages',
  'lang.search_country': 'Search countries',
  'lang.spoken_in': 'Spoken in {country}',
  // lock
  'lock.bio_enable': 'Confirm your fingerprint to enable for BillZap',
  'lock.bio_unlock': 'Unlock BillZap with your fingerprint',
  'lock.enter': 'Enter your 4-digit PIN',
  'lock.unlock': 'Unlock BillZap',
  'lock.use_fp': 'Use fingerprint',
  'lock.wrong': 'Wrong PIN. Try again.',
  // ls
  'ls.add_fp': 'Add Fingerprint?',
  'ls.add_fp_msg': 'Unlock BillZap with your fingerprint instead of typing your PIN every time. You can still use your PIN as backup.',
  'ls.backup_error': 'Backup error: {e}',
  'ls.backup_failed_warn': 'Backup failed: {e}. Continuing — but you won\'t be able to recover if you forget your PIN.',
  'ls.confirm_pin': 'Confirm PIN',
  'ls.confirm_pin_sub': 'Re-enter your PIN to confirm',
  'ls.created': 'Backup created ✓',
  'ls.creating': 'Creating encrypted backup...',
  'ls.enable_fp': 'Enable Fingerprint',
  'ls.enabled': 'App Lock Enabled 🔒',
  'ls.enabled_msg': 'BillZap will lock when you switch apps and return after 1 minute. Make sure you remember your PIN!',
  'ls.important': 'Important',
  'ls.important_msg': 'If you forget your PIN AND lose your backup file, your data cannot be recovered.',
  'ls.intro': 'Your PIN will be used both to unlock the app AND to encrypt a backup of your data. Keep your PIN safe — and we\'ll show you how to back it up next.',
  'ls.mismatch': 'PINs don\'t match. Please try again.',
  'ls.moment': 'This will take a moment',
  'ls.no_fingerprint': 'Fingerprint not available. Make sure a fingerprint is registered in your phone Settings → Biometrics. PIN-only lock will be set up.',
  'ls.send': 'Send via WhatsApp / Email',
  'ls.send_hint': 'Send this backup to yourself on WhatsApp or email for extra safety. If you ever lose your phone, you can restore from it.',
  'ls.set_pin': 'Set 4-digit PIN',
  'ls.set_pin_sub': 'Choose a PIN you\'ll remember',
  'ls.share_subject': 'BillZap Backup — Keep this safe',
  'ls.share_text': 'My BillZap backup file. I\'ll need this if I ever forget my PIN. Keep it safe!',
  'ls.skip_fp': 'Skip — PIN only',
  'ls.skip_now': 'Skip for now',
  'ls.title': 'Set up App Lock',
  'ls.understand': 'I understand, continue',
  'ls.unknown': 'Unknown',
  // nf
  'nf.back': 'Back to home',
  'nf.msg': 'That link does not lead anywhere in BillZap.',
  'nf.title': 'Nothing here',
  // onboard
  'onboard.address_hint': '123 Main Road',
  'onboard.select': 'Select',
  'onboard.select_country': 'Select a country',
  // pc
  'pc.add_more': 'Add {a}, {b} & more',
  'pc.add_one': 'Add {a}',
  'pc.add_two': 'Add {a} & {b}',
  'pc.address': 'address',
  'pc.business_name': 'business name',
  'pc.phone': 'phone number',
  'pc.upi': 'UPI ID',
  // prod
  'prod.delete_msg': 'Invoices that already list this item keep their line — only the saved item goes.',
  'prod.left': '{n} left',
  'prod.margin_pct': 'Margin: {pct}%',
  // pv
  'pv.customer_name': 'Customer Name',
  'pv.delete': 'Delete Invoice',
  'pv.delete_btn': 'Delete invoice',
  'pv.delete_msg': '{no} will be removed for good. This cannot be undone.',
  'pv.delete_sub': 'Permanently remove this invoice',
  'pv.delete_title': 'Delete this invoice?',
  'pv.download_pdf': 'Download PDF',
  'pv.edit': 'Edit Invoice',
  'pv.mark_paid': 'Mark as Paid',
  'pv.mark_paid_sub': 'Record payment received',
  'pv.mark_unpaid': 'Mark as Unpaid',
  'pv.mark_unpaid_sub': 'Undo paid status',
  'pv.marked_paid': 'Marked as paid',
  'pv.marked_unpaid': 'Marked as unpaid',
  'pv.none': 'No invoice selected',
  'pv.pdf_error': 'Could not create the PDF: {e}',
  'pv.pdf_ready': 'PDF ready',
  'pv.pdf_sub': 'Professional invoice PDF',
  'pv.pdf_title': 'Download & Share PDF',
  'pv.print_error': 'Could not print: {e}',
  'pv.print_sub': 'Print via Wi-Fi or Bluetooth',
  'pv.print_title': 'Print Invoice',
  'pv.send_whatsapp': 'Send on WhatsApp',
  'pv.share_subject': 'Invoice {no}',
  'pv.share_text': 'Invoice {no} — {amount}',
  'pv.title': 'Invoice',
  'pv.unpaid_btn': 'Mark unpaid',
  'pv.unpaid_msg': 'The status goes back to Sent. Nothing else changes.',
  'pv.unpaid_title': 'Mark as unpaid?',
  'pv.updated': 'Invoice updated',
  // region
  'region.canton': 'Canton',
  'region.community': 'Community',
  'region.county': 'County',
  'region.division': 'Division',
  'region.emirate': 'Emirate',
  'region.nation': 'Nation',
  'region.oblast': 'Oblast',
  'region.prefecture': 'Prefecture',
  'region.province': 'Province',
  'region.region': 'Region',
  'region.state': 'State',
  'region.voivodeship': 'Voivodeship',
  // rep
  'rep.export': 'Export',
  'rep.last_6': 'Last 6 months',
  // set
  'set.all_set': 'All set',
  'set.bank_code': 'Bank code (SWIFT / routing)',
  'set.bank_sub': 'Printed on the bill so customers can transfer',
  'set.biz_name_hint': 'e.g. Ravi Electronics',
  'set.browser_fail': 'Could not open browser',
  'set.country_label': 'Country',
  'set.fix_fields': 'Fix the highlighted fields first',
  'set.invoice_sub': 'How new bills are numbered and worded',
  'set.no_taxid': 'No {taxid} yet',
  'set.place_of_business': 'Place of business',
  'set.postal_code': 'Postal code',
  'set.prefix_helper': 'Your next bill will be numbered from this',
  'set.profile_sub': 'Printed at the top of every bill',
  'set.reach_sub': 'Shown on the bill and the WhatsApp message',
  'set.reach_title': 'How customers reach you',
  'set.region_hint': 'Region or province',
  'set.select_region': 'Select {label}',
  'set.street_hint': 'Street, area',
  'set.tax_name_hint': 'VAT',
  'set.taxid_helper': 'Leave blank if you are not registered',
  'set.terms_hint': 'Payment due within 30 days.',
  'set.to_go': '{n} to go',
  'set.trade_from': 'Where you trade from',
  'set.trade_from_in': 'State decides CGST/SGST against IGST',
  'set.trade_from_sub': 'The address printed on every invoice',
  'set.upi_helper': 'Customers scan this to pay you directly',
  'set.upi_sub': 'Becomes the QR code on every unpaid bill',
  'set.upi_title': 'UPI',
  'set.your_business': 'Your business',
  // share
  'share.body': 'I\'m using BillZap to send professional invoices in seconds.\n• 100% offline • No sign-up • Free forever\n• Works in {count} languages\n• Voice billing in your language',
  'share.download': 'Download: {url}',
  'share.subject': 'Try BillZap — free billing app',
  'share.title': '*BillZap* — free billing for small shops',
  'share.try': 'Try it: {url}',
  // slab
  'slab.essentials': 'Essentials',
  'slab.exempt': 'Exempt',
  'slab.general': 'General',
  'slab.luxury': 'Luxury',
  'slab.sin': 'Sin tax',
  'slab.standard': 'Standard',
  'slab.stones': 'Stones',
  // splash
  'splash.made_simple': 'Billing made simple',
  // upi
  'upi.amount_due': 'Amount due',
  'upi.copied': 'UPI link copied',
  'upi.copy': 'Copy UPI link',
  'upi.enable': 'Enable UPI payments',
  'upi.enable_sub': 'Add your UPI ID in Settings to let customers pay instantly via QR.',
  'upi.instant': 'Instant payment • All UPI apps',
  'upi.invalid': 'Invalid UPI ID format',
  'upi.invalid_sub': '"{vpa}" is not a valid UPI ID. It should look like name@bank',
  'upi.no_app': 'No UPI app installed',
  'upi.pay_now': 'Pay now',
  'upi.pay_via': 'Pay via UPI',
  'upi.ref': 'Ref: {no}',
  'upi.setup': 'Set up',
  // val
  'val.email': 'Invalid email',
  'val.field': 'Field',
  'val.gstin_format': 'Invalid GSTIN format',
  'val.gstin_len': 'GSTIN must be 15 characters',
  'val.ifsc': 'Invalid IFSC (e.g. SBIN0001234)',
  'val.phone': 'Invalid phone number',
  'val.phone_in': 'Invalid Indian mobile number',
  'val.pincode': 'Invalid 6-digit pincode',
  'val.postal': 'Invalid postal code',
  'val.required': '{field} is required',
  'val.taxid': 'Invalid {taxid}',
  'val.upi': 'Should look like name@bank',
  // voice
  'voice.choose_lang': 'Choose speech language',
  'voice.extracted': 'Extracted',
  'voice.heard': 'I heard:',
  'voice.items': 'Items',
  'voice.listening': 'Listening...',
  'voice.no_audio': 'Couldn\'t capture audio',
  'voice.no_items': 'No items detected. Try speaking again with clearer pricing.',
  'voice.not_installed': 'Not installed on this device',
  'voice.retry': 'Retry',
  'voice.speech_error': 'Speech error: {e}',
  'voice.tap_again': 'Tap mic to record again',
  'voice.tap_speak': 'Tap mic and speak',
  'voice.tip1': 'Speak slowly and clearly',
  'voice.tip2': 'Mention quantity, item name, and price',
  'voice.tip3': 'Say "for [Customer Name]" at the start',
  'voice.tip4': 'Separate items with "and" or pause',
  'voice.tip5': 'You can edit everything in the next step',
  'voice.tips': 'Voice tips',
  'voice.title': 'Voice Invoice',
  'voice.try': 'Try:',
  'voice.try_again': 'Try again',
  // wa
  'wa.due': 'Due: {date}',
  'wa.greeting': 'Hi {name},',
  'wa.pay_upi': '*Pay instantly via UPI:*',
  'wa.ready': 'Your invoice *{no}* for *{amount}* is ready.',
  'wa.sent_via': '— Sent via BillZap',
  'wa.thanks': 'Thank you.',
  // welcome
  'welcome.barrier': 'Welcome',
  'welcome.cta': 'Set up profile',
  'welcome.f1': '{tax}-ready invoices',
  'welcome.f1_sub': 'Tax worked out on every bill',
  'welcome.f1_sub_in': 'CGST, SGST and IGST worked out for you',
  'welcome.f2': 'UPI QR on every bill',
  'welcome.f2_sub': 'Customers pay by scanning, straight away',
  'welcome.f3': 'Your name on every PDF',
  'welcome.f3_sub': 'Shared to WhatsApp with your branding',
  'welcome.f4': 'Works with no signal',
  'welcome.f4_sub': 'Everything stays on this phone',
  'welcome.incomplete': 'Profile incomplete',
  'welcome.later': 'Not now',
  'welcome.sub': 'A minute now, and every bill you send carries your name and your {taxid}.',
  'welcome.title': 'Set up your shop',
};

// ── Loaded languages ──────────────────────────────────────────
//
// English always; plus whichever language is on screen. Switching drops
// the previous one.
final Map<String, Map<String, String>> _loaded = {'en': _en};

String _currentLangCache = 'en';

/// Read a language's file into memory. True if it is ready to show.
/// English needs no file. An id the app does not know is refused rather
/// than half-applied.
Future<bool> loadLanguage(String id) async {
  if (_loaded.containsKey(id)) return true;
  if (appLocaleFor(id) == null) return false;
  try {
    final raw = await rootBundle.loadString('assets/i18n/$id.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _loaded[id] = {
      for (final e in decoded.entries)
        if (e.value is String) e.key: e.value as String,
    };
    return true;
  } catch (_) {
    return false;
  }
}

Set<String>? _available;

/// Languages that have a translation file in this build, plus English.
/// A language in the list without a file is shown as coming soon rather
/// than offered and then silently refused.
Future<Set<String>> availableLanguageIds() async {
  if (_available != null) return _available!;
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    _available = {
      'en',
      for (final a in manifest.listAssets())
        if (a.startsWith('assets/i18n/') && a.endsWith('.json'))
          a.substring('assets/i18n/'.length, a.length - '.json'.length),
    };
  } catch (_) {
    // Cannot tell: offer everything, as before.
    _available = {for (final l in kAppLocales) l.id};
  }
  return _available!;
}

/// Tests read the JSON straight off disk and hand it in here, since a
/// plain unit test has no asset bundle.
@visibleForTesting
void registerTranslations(String id, Map<String, String> strings) {
  _loaded[id] = strings;
}

// ── State management ──────────────────────────────────────────
class LanguageNotifier extends Notifier<String> {
  // main() has already loaded the saved language before the first
  // frame, so this is the real answer, not a placeholder that flips a
  // moment later.
  @override
  String build() => _currentLangCache;

  Future<void> setLanguage(String id) async {
    if (!await loadLanguage(id)) return;
    _currentLangCache = id;
    _loaded.removeWhere((k, _) => k != 'en' && k != id);
    state = id;
    try {
      final box = Hive.isBoxOpen('settings')
          ? Hive.box('settings')
          : await Hive.openBox('settings');
      await box.put('language', id);
    } catch (_) {}
  }
}

final languageProvider =
    NotifierProvider<LanguageNotifier, String>(LanguageNotifier.new);

/// Every key a language defines, for the tests that have to sweep all
/// of them — a leaked placeholder is only findable by looking at every
/// string, and that is exactly the check worth automating.
Iterable<String> allTranslationKeys(String langCode) =>
    (_loaded[langCode] ?? _en).keys;

/// Every key English defines: the full set a translation should cover.
Iterable<String> get englishKeys => _en.keys;

/// English exactly as written, placeholders and all — for the tests
/// that check a translation kept every {placeholder} its English has.
@visibleForTesting
String rawEnglishString(String key) => _en[key] ?? '';

// ── Country placeholders ──────────────────────────────────────
//
// The app shipped as an Indian app, so "GST" and "GSTIN" are written
// into a few hundred strings across every language. Re-translating
// every one of them per country is not possible and would not be an
// improvement; what is wrong is not the translation but the noun.
//
// So those strings now carry a placeholder instead of the noun, and it
// is filled in at lookup from the country the shop is in:
//
//   {tax}    GST, VAT, Sales Tax, Consumption Tax
//   {taxid}  GSTIN, TRN, VAT number, Tax ID
//
// A translator writes "{tax} लागू करें" and a Dubai shopkeeper reading
// Hindi gets "VAT लागू करें". The grammar stays the translator's and
// the noun stays the country's.
//
// Keys that are India-specific on purpose — GSTR-1, the CGST/SGST/IGST
// labels — deliberately keep the literal word, because those things are
// called that and nothing else.
String _fillCountry(String value) {
  if (!value.contains('{')) return value;
  return value
      .replaceAll('{tax}', activeTaxName)
      .replaceAll('{taxid}', activeTaxIdLabel)
      // Most countries have no item classification code on a retail
      // bill. Where a field is shown anyway — the catalog's, which is
      // free-text and harmless — it is labelled generically rather
      // than left blank.
      // 'Item', not 'Item code': the strings that use this
      // placeholder already supply the word "code" around it, so the
      // label reads "HSN Code (optional)" in India and "Item Code
      // (optional)" everywhere else.
      .replaceAll('{itemcode}', activeItemCodeLabel ?? 'Item')
      // The shop's own symbol. "Price (₹)" was printed for every shop.
      .replaceAll('{currency}', activeCurrencySymbol);
}

String _lookup(String lang, String key, Map<String, Object?>? args) {
  final raw = _loaded[lang]?[key] ?? _en[key] ?? key;
  var out = _fillCountry(raw);
  if (args != null) {
    // After the country nouns, so a customer called "{tax}" stays one.
    for (final e in args.entries) {
      out = out.replaceAll('{${e.key}}', '${e.value ?? ''}');
    }
  }
  return out;
}

// ── Translate functions ───────────────────────────────────────

/// In a ConsumerWidget. Watches the language, so the widget rebuilds
/// when it changes.
String tr(String key, WidgetRef ref, [Map<String, Object?>? args]) {
  final lang = ref.watch(languageProvider);
  return _lookup(lang, key, args);
}

/// In a given language, regardless of the one on screen.
String trKey(String key, String langCode, [Map<String, Object?>? args]) =>
    _lookup(langCode, key, args);

/// Anywhere — a static helper, a dialog, a snackbar. Reads the language
/// on screen. Safe in widgets too: changing the language rebuilds the
/// whole tree (PaletteScope), so nothing keeps a stale string.
String trGlobal(String key, [Map<String, Object?>? args]) =>
    _lookup(_currentLangCache, key, args);

/// A count: picks `key.one` for exactly one and `key.other` for
/// everything else, with {n} filled in. Translators whose language has
/// more plural forms than two write '.other' so it reads for any number
/// ("Invoices: {n}"), which is always grammatical.
String trCount(String key, num n) =>
    trGlobal(n == 1 ? '$key.one' : '$key.other', {'n': n});

/// A country's name in the language on screen: 'country.JP' from the
/// language file, else the English name from countries.dart, else the
/// code. Never blank.
String countryDisplayName(String code) {
  final translated = _loaded[_currentLangCache]?['country.$code'];
  if (translated != null && translated.trim().isNotEmpty) return translated;
  return countryFor(code)?.name ?? code;
}

/// The language on screen, as a locale.
AppLocale currentLanguage(String code) => appLocaleFor(code) ?? kEnglish;

// ── Startup ───────────────────────────────────────────────────

/// Load the saved language before the first frame, so the app opens in
/// it rather than flashing English. Unknown or unreadable: English.
Future<void> initGlobalLanguage() async {
  try {
    final box = Hive.box('settings');
    final saved = box.get('language', defaultValue: 'en') as String;
    if (await loadLanguage(saved)) _currentLangCache = saved;
  } catch (_) {}
}

/// The language id currently selected: 'en', 'hi', 'zh-Hans' and so on.
///
/// Callers that need the code itself rather than a translated string
/// must use this. Asking trGlobal() for it cannot work: trGlobal
/// returns the key back when it does not find one, so a lookup of a
/// non-existent key yields that key as a plausible-looking String and
/// nothing reports an error. That is exactly what the voice screen did,
/// and it pinned speech recognition to en_IN for every user in every
/// language. See voice_invoice_screen.dart.
String get currentLangCode => _currentLangCache;

/// Whether the language on screen reads right to left.
bool get currentLangIsRtl => appLocaleFor(_currentLangCache)?.rtl ?? false;
