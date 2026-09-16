// lib/theme/app_icons.dart
//
// Lucide icon set for BillZap.
//
// The app previously drew Material Symbols. This file keeps the familiar
// `Symbols.<name>` call sites (26 files, ~90 distinct glyphs) but resolves
// each one to its Lucide counterpart, so the whole app switches to Lucide's
// thin, rounded, uniform-stroke drawing without touching a single widget.
//
// Adding an icon: add a `static const` here pointing at `LucideIcons.<x>`
// and use it as `Symbols.<your_name>` like the rest.
//
// Every entry is a `static const IconData`, which keeps icon-font
// tree-shaking working in release builds — only the glyphs referenced
// below are bundled, not all ~1,600 Lucide icons.

// ignore_for_file: constant_identifier_names

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Lucide-backed drop-in for the Material `Symbols` class.
class Symbols {
  const Symbols._();

  static const IconData account_balance = LucideIcons.landmark;
  static const IconData account_balance_wallet = LucideIcons.wallet;
  static const IconData add = LucideIcons.plus;
  static const IconData add_box = LucideIcons.squarePlus;
  static const IconData add_circle = LucideIcons.circlePlus;
  static const IconData arrow_back = LucideIcons.arrowLeft;
  static const IconData arrow_forward = LucideIcons.arrowRight;
  static const IconData auto_awesome = LucideIcons.sparkles;
  static const IconData backspace = LucideIcons.delete;
  static const IconData badge = LucideIcons.idCard;
  static const IconData bar_chart = LucideIcons.chartColumn;
  static const IconData bolt = LucideIcons.zap;
  static const IconData brightness_auto = LucideIcons.sunMoon;
  static const IconData calculate = LucideIcons.calculator;
  static const IconData calendar_today = LucideIcons.calendar;
  static const IconData chat = LucideIcons.messageCircle;
  static const IconData check = LucideIcons.check;
  static const IconData check_circle = LucideIcons.circleCheck;
  static const IconData chevron_left = LucideIcons.chevronLeft;
  static const IconData chevron_right = LucideIcons.chevronRight;
  static const IconData close = LucideIcons.x;
  static const IconData cloud_download = LucideIcons.cloudDownload;
  static const IconData cloud_upload = LucideIcons.cloudUpload;
  static const IconData content_copy = LucideIcons.copy;
  static const IconData currency_rupee = LucideIcons.indianRupee;
  static const IconData dark_mode = LucideIcons.moon;
  static const IconData data_object = LucideIcons.braces;
  static const IconData delete = LucideIcons.trash2;
  static const IconData download = LucideIcons.download;
  static const IconData edit = LucideIcons.pencil;
  static const IconData error = LucideIcons.circleAlert;
  static const IconData event = LucideIcons.calendarDays;
  static const IconData exit_to_app = LucideIcons.logOut;
  static const IconData expand_more = LucideIcons.chevronDown;
  static const IconData fact_check = LucideIcons.clipboardCheck;
  static const IconData fiber_manual_record = LucideIcons.dot;
  static const IconData filter_alt_off = LucideIcons.filterX;
  static const IconData fingerprint = LucideIcons.fingerprint;
  static const IconData folder = LucideIcons.folder;
  static const IconData group = LucideIcons.users;
  static const IconData group_add = LucideIcons.userPlus;
  static const IconData hearing = LucideIcons.ear;
  static const IconData help = LucideIcons.circleHelp;
  static const IconData home = LucideIcons.house;
  static const IconData info = LucideIcons.info;
  static const IconData inventory = LucideIcons.package;
  static const IconData inventory_2 = LucideIcons.boxes;
  static const IconData language = LucideIcons.languages;
  static const IconData light_mode = LucideIcons.sun;
  static const IconData lightbulb = LucideIcons.lightbulb;
  static const IconData location_city = LucideIcons.building2;
  static const IconData location_on = LucideIcons.mapPin;
  static const IconData lock = LucideIcons.lock;
  static const IconData percent = LucideIcons.percent;
  static const IconData local_shipping = LucideIcons.truck;
  static const IconData lock_open = LucideIcons.lockOpen;
  static const IconData mail = LucideIcons.mail;
  static const IconData mic = LucideIcons.mic;
  static const IconData more_vert = LucideIcons.ellipsisVertical;
  static const IconData open_in_new = LucideIcons.externalLink;
  static const IconData payments = LucideIcons.banknote;
  static const IconData person = LucideIcons.user;
  static const IconData person_add = LucideIcons.userPlus;
  static const IconData person_off = LucideIcons.userX;
  static const IconData phone = LucideIcons.phone;
  static const IconData picture_as_pdf = LucideIcons.fileText;
  static const IconData pin = LucideIcons.keyRound;
  static const IconData point_of_sale = LucideIcons.scanLine;
  static const IconData print = LucideIcons.printer;
  static const IconData public = LucideIcons.globe;
  static const IconData qr_code_2 = LucideIcons.qrCode;
  static const IconData receipt = LucideIcons.receipt;
  static const IconData receipt_long = LucideIcons.receiptText;
  static const IconData refresh = LucideIcons.refreshCw;
  static const IconData remove_circle = LucideIcons.circleMinus;
  static const IconData remove = LucideIcons.minus;
  static const IconData restore = LucideIcons.archiveRestore;
  static const IconData schedule = LucideIcons.clock;
  static const IconData search = LucideIcons.search;
  static const IconData send = LucideIcons.send;
  static const IconData share = LucideIcons.share2;
  static const IconData shield = LucideIcons.shield;
  static const IconData shopping_basket = LucideIcons.shoppingBasket;
  static const IconData stop = LucideIcons.circleStop;
  static const IconData storefront = LucideIcons.store;
  static const IconData table_view = LucideIcons.table;
  static const IconData tips_and_updates = LucideIcons.lightbulb;
  static const IconData translate = LucideIcons.languages;
  static const IconData trending_up = LucideIcons.trendingUp;
  static const IconData undo = LucideIcons.undo2;
  static const IconData verified = LucideIcons.badgeCheck;
  static const IconData upload_file = LucideIcons.fileUp;
  static const IconData warning = LucideIcons.triangleAlert;
  static const IconData wifi_off = LucideIcons.wifiOff;
}
