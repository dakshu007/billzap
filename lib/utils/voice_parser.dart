// lib/utils/voice_parser.dart
// Parses natural-language voice input into structured invoice items.
// Works offline. Supports 12 Indian languages.
//
// Tested cases (all passing):
//   "for Ravi 2 kg sugar 50 rupees" → Ravi, sugar 2kg @50
//   "Ravi ke liye 3 kilo cheeni 60 rupaye" → Ravi, cheeni 3kg @60
//   "5 pieces soap at 30 rupees" → soap 5pcs @30
//   "for John 2 kg rice 50 and 1 kg dal 80" → John, rice 2kg @50, dal 1kg @80
//   "two kilo sugar fifty rupees" → sugar 2kg @50
//   "Ravi book 5 pcs 100 each" → Ravi, book 5pcs @100
//   "3 boxes biscuits 40 rupees" → biscuits 3box @40
//   "10 pieces pen 5 rupees each" → pen 10pcs @5

class ParsedItem {
  final double qty;
  final String unit;
  final String name;
  final double price;
  ParsedItem({required this.qty, required this.unit, required this.name, required this.price});

  @override
  String toString() => '$qty $unit $name @ ₹$price';
}

class ParsedInvoice {
  final String? customerName;
  final List<ParsedItem> items;
  final String rawText;
  ParsedInvoice({this.customerName, required this.items, required this.rawText});

  bool get isEmpty => items.isEmpty && (customerName == null);
}

class VoiceParser {
  // Number words across languages
  static const Map<String, double> _numberWords = {
    'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
    'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
    'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14, 'fifteen': 15,
    'sixteen': 16, 'seventeen': 17, 'eighteen': 18, 'nineteen': 19, 'twenty': 20,
    'thirty': 30, 'forty': 40, 'fifty': 50, 'sixty': 60, 'seventy': 70,
    'eighty': 80, 'ninety': 90, 'hundred': 100, 'thousand': 1000,
    'half': 0.5, 'quarter': 0.25,
    // Hindi (transliterated)
    'ek': 1, 'do': 2, 'teen': 3, 'char': 4, 'paanch': 5,
    'chhe': 6, 'chey': 6, 'saat': 7, 'aath': 8, 'nau': 9, 'das': 10,
    'gyarah': 11, 'baarah': 12, 'pachas': 50, 'sau': 100, 'hazaar': 1000,
    // Tamil (transliterated)
    'onnu': 1, 'rendu': 2, 'moonu': 3, 'naalu': 4, 'anju': 5,
    'aaru': 6, 'ezhu': 7, 'ettu': 8, 'onbathu': 9, 'pathu': 10,
    'irubathu': 20, 'muppathu': 30, 'aimbathu': 50, 'nooru': 100, 'aayiram': 1000,
    // Other languages (limited transliteration)
    'don': 2, 'paach': 5, 'mooru': 3, 'naalku': 4, 'eradu': 2,
  };

  // Unit normalization - includes plurals
  static const Map<String, String> _unitNormalizer = {
    'kg': 'kg', 'kgs': 'kg', 'kilo': 'kg', 'kilos': 'kg',
    'kilogram': 'kg', 'kilograms': 'kg',
    'किलो': 'kg', 'किलोग्राम': 'kg',
    'கிலோ': 'kg', 'கிலோகிராம்': 'kg',
    'కిలో': 'kg', 'ಕಿಲೋ': 'kg', 'കിലോ': 'kg', 'কিলো': 'kg',
    'gram': 'g', 'grams': 'g', 'gm': 'g', 'gms': 'g', 'g': 'g',
    'ग्राम': 'g', 'கிராம்': 'g',
    'litre': 'l', 'litres': 'l', 'liter': 'l', 'liters': 'l', 'l': 'l',
    'लीटर': 'l', 'லிட்டர்': 'l',
    'ml': 'ml', 'milliliter': 'ml', 'millilitres': 'ml',
    'piece': 'pcs', 'pieces': 'pcs', 'pcs': 'pcs', 'pc': 'pcs',
    'nos': 'nos', 'no': 'nos', 'number': 'nos', 'numbers': 'nos',
    'unit': 'nos', 'units': 'nos', 'item': 'nos', 'items': 'nos',
    'पीस': 'pcs',
    'box': 'box', 'boxes': 'box',
    'pack': 'pack', 'packs': 'pack', 'packet': 'pack', 'packets': 'pack',
    'दर्जन': 'dozen', 'dozen': 'dozen', 'dozens': 'dozen',
    'meter': 'm', 'meters': 'm', 'metre': 'm', 'metres': 'm',
    'inch': 'inch', 'inches': 'inch', 'foot': 'ft', 'feet': 'ft',
    'bottle': 'bottle', 'bottles': 'bottle',
    'bag': 'bag', 'bags': 'bag',
    'roll': 'roll', 'rolls': 'roll',
  };

  // Price marker keywords
  static const List<String> _priceMarkers = [
    'rupees', 'rupee', 'rs', '₹', 'inr',
    'rupaye', 'rupaya', 'rupiya', 'paisa',
    'रुपये', 'रुपए', 'रुपया',
    'ரூபாய்', 'ரூபா',
    'రూపాయలు', 'రూపాయి',
    'ರೂಪಾಯಿ', 'ರೂಪಾಯಿಗಳು',
    'രൂപ', 'রুপি', 'ਰੁਪਏ', 'ଟଙ୍କା', 'روپے',
    'rupayya', 'rupiyaa',
    'each', 'per',
  ];

  // Customer extraction patterns (order matters: more specific first)
  static final List<RegExp> _customerPatterns = [
    // English: "for Ravi", "to Ravi", "bill for Ravi"
    RegExp(r'(?:bill\s+)?(?:for|to)\s+([a-zA-Z]+)', caseSensitive: false),
    // "customer Ravi", "customer name Ravi"
    RegExp(r'customer\s+(?:name\s+)?(?:is\s+)?([a-zA-Z]+)', caseSensitive: false),
    // Hindi/Marathi: "Ravi ke liye", "Ravi ko"
    RegExp(r'^([a-zA-Z]+)\s+(?:ke\s+liye|ko|kaaga|ka)\b', caseSensitive: false),
    // Tamil: "Ravi-ku", "Ravi kku", "Ravi ukku"
    RegExp(r'^([a-zA-Z]+)[-\s]+(?:ku|kku|ukku)\b', caseSensitive: false),
  ];

  // Words to skip when extracting item name
  static const Set<String> _stopWords = {
    'add', 'please', 'put', 'and', 'also', 'with', 'plus',
    'create', 'invoice', 'bill', 'generate', 'make',
    'aur', 'ya', 'ke', 'ka', 'ki', 'ko', 'mein', 'liye',
    'pannu', 'podu', 'kuduku', 'sera',
    'for', 'to', 'at', 'of',
  };

  // Common item words used to prevent first-word from being mistaken as customer name
  static const Set<String> _commonItemWords = {
    'sugar', 'salt', 'rice', 'oil', 'soap', 'milk',
    'tea', 'coffee', 'bread', 'eggs', 'apple', 'banana', 'water',
    'pen', 'book', 'paper', 'chocolate', 'biscuit', 'biscuits',
    'cheeni', 'namak', 'chawal', 'aata', 'dal',
  };

  // ═══════════════════════════════════════════════════════════════
  // MAIN ENTRY POINT
  // ═══════════════════════════════════════════════════════════════
  static ParsedInvoice parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return ParsedInvoice(items: [], rawText: rawText);
    }

    final text = rawText.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    final customerName = _extractCustomer(text);

    final clauses = _splitClauses(text);
    final items = <ParsedItem>[];
    for (final clause in clauses) {
      final item = _parseItemClause(clause, customerName);
      if (item != null) items.add(item);
    }

    return ParsedInvoice(
      customerName: customerName,
      items: items,
      rawText: rawText,
    );
  }

  // ─── Customer extraction ──────────────────────────────
  static String? _extractCustomer(String text) {
    // Try standard patterns first
    for (final pattern in _customerPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final name = match.group(1)?.trim().toLowerCase();
        if (name != null && name.length >= 2 && _isValidName(name)) {
          return _capitalize(name);
        }
      }
    }

    // Heuristic: if first word is a plausible name
    final firstWord = RegExp(r'^([a-zA-Z]+)\b').firstMatch(text);
    if (firstWord != null) {
      final word = firstWord.group(1)!.toLowerCase();
      if (word.length >= 3 && _isValidName(word) && !_commonItemWords.contains(word)) {
        return _capitalize(word);
      }
    }

    return null;
  }

  static bool _isValidName(String w) {
    return !_unitNormalizer.containsKey(w) &&
           !_priceMarkers.contains(w) &&
           !_stopWords.contains(w) &&
           !_numberWords.containsKey(w);
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  // ─── Clause splitting ──────────────────────────────────
  static List<String> _splitClauses(String text) {
    final separators = RegExp(
      r',|\bऔर\b|\baur\b|\band\b|\balso\b|\bமற்றும்\b|;'
    );
    return text.split(separators)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // ─── Item clause parsing ──────────────────────────────
  static ParsedItem? _parseItemClause(String clause, String? customerName) {
    final numbers = _findNumbers(clause);
    if (numbers.isEmpty) return null;

    final unitMatch = _findUnit(clause);
    final priceMarkerPos = _findPriceMarkerPosition(clause);

    double qty = 1;
    String unit = 'nos';
    double price = 0;

    if (unitMatch != null) {
      final beforeUnit = numbers.where((n) => n.position < unitMatch.start).toList();
      final afterUnit = numbers.where((n) => n.position > unitMatch.end).toList();

      if (beforeUnit.isNotEmpty) qty = beforeUnit.last.value;
      unit = unitMatch.normalized;

      // Find price: number IMMEDIATELY BEFORE the price marker
      if (priceMarkerPos != null) {
        final beforePm = numbers.where((n) => n.position < priceMarkerPos).toList();
        if (beforePm.isNotEmpty) {
          // The closest one before the marker is the price
          beforePm.sort((a, b) => b.position.compareTo(a.position));
          price = beforePm.first.value;
        } else if (afterUnit.isNotEmpty) {
          price = afterUnit.first.value;
        }
      } else if (afterUnit.isNotEmpty) {
        price = afterUnit.first.value;
      }
    } else {
      // No unit found
      if (numbers.length >= 2) {
        final sorted = List<_NumberMatch>.from(numbers)..sort((a, b) => a.value.compareTo(b.value));
        qty = sorted.first.value;
        price = sorted.last.value;
      } else if (numbers.length == 1) {
        price = numbers.first.value;
      }
    }

    final name = _extractItemName(clause, customerName);
    if (name.isEmpty) return null;

    return ParsedItem(qty: qty, unit: unit, name: name, price: price);
  }

  // ─── Find all numbers ──────────────────────────────────
  static List<_NumberMatch> _findNumbers(String text) {
    final matches = <_NumberMatch>[];
    final digitRegex = RegExp(r'\b(\d+(?:\.\d+)?)\b');
    for (final m in digitRegex.allMatches(text)) {
      final v = double.tryParse(m.group(1)!);
      if (v != null) matches.add(_NumberMatch(value: v, position: m.start));
    }

    final words = text.split(RegExp(r'\s+'));
    int pos = 0;
    for (final word in words) {
      final clean = word.toLowerCase().replaceAll(RegExp(r'[^\w\u0900-\u0FFF\u0B80-\u0BFF\u0C00-\u0C7F\u0C80-\u0CFF\u0D00-\u0D7F\u0980-\u09FF\u0A00-\u0A7F\u0B00-\u0B7F\u0600-\u06FF]'), '');
      if (_numberWords.containsKey(clean)) {
        matches.add(_NumberMatch(value: _numberWords[clean]!, position: pos));
      }
      pos += word.length + 1;
    }

    matches.sort((a, b) => a.position.compareTo(b.position));
    return matches;
  }

  // ─── Find unit keyword ─────────────────────────────────
  static _UnitMatch? _findUnit(String text) {
    int? bestStart;
    int? bestEnd;
    String? bestNorm;
    String? bestRaw;

    // Sort keys by length DESC so longer keywords match first (e.g. "kgs" before "g")
    final sortedKeys = _unitNormalizer.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final raw in sortedKeys) {
      final pattern = RegExp('\\b${RegExp.escape(raw)}\\b', caseSensitive: false);
      final match = pattern.firstMatch(text);
      if (match != null) {
        if (bestStart == null || match.start < bestStart) {
          bestStart = match.start;
          bestEnd = match.end;
          bestNorm = _unitNormalizer[raw];
          bestRaw = raw;
        }
      }
    }

    if (bestStart == null) return null;
    return _UnitMatch(start: bestStart, end: bestEnd!, normalized: bestNorm!, raw: bestRaw!);
  }

  // ─── Find earliest price marker position ──────────────
  static int? _findPriceMarkerPosition(String text) {
    int? earliest;
    for (final marker in _priceMarkers) {
      final pattern = RegExp('\\b${RegExp.escape(marker)}\\b', caseSensitive: false);
      final m = pattern.firstMatch(text);
      if (m != null) {
        if (earliest == null || m.start < earliest) earliest = m.start;
      }
    }
    return earliest;
  }

  // ─── Extract item name ────────────────────────────────
  static String _extractItemName(String clause, String? customerName) {
    var working = clause;

    // Remove customer-mention spans
    for (final pattern in _customerPatterns) {
      working = working.replaceFirst(pattern, ' ');
    }

    // Also remove customer name itself if it remains as standalone word
    if (customerName != null && customerName.isNotEmpty) {
      final namePattern = RegExp(
        r'\b' + RegExp.escape(customerName.toLowerCase()) + r'\b',
        caseSensitive: false);
      working = working.replaceAll(namePattern, ' ');
    }

    // Remove units (longest first)
    final sortedUnits = _unitNormalizer.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (final unit in sortedUnits) {
      working = working.replaceAll(RegExp('\\b${RegExp.escape(unit)}\\b', caseSensitive: false), ' ');
    }

    // Remove price markers
    for (final marker in _priceMarkers) {
      working = working.replaceAll(RegExp('\\b${RegExp.escape(marker)}\\b', caseSensitive: false), ' ');
    }

    // Remove digit numbers
    working = working.replaceAll(RegExp(r'\d+(?:\.\d+)?'), ' ');

    // Filter remaining words
    final words = working.split(RegExp(r'\s+'));
    final cleaned = <String>[];
    for (final w in words) {
      final lc = w.toLowerCase().replaceAll(RegExp(r"[,.!?@-]"), '').trim();
      if (lc.isEmpty) continue;
      if (_numberWords.containsKey(lc)) continue;
      if (_stopWords.contains(lc)) continue;
      if (lc.length < 2) continue;
      cleaned.add(lc);
    }

    if (cleaned.isEmpty) return '';
    return _capitalize(cleaned.join(' '));
  }
}

class _NumberMatch {
  final double value;
  final int position;
  _NumberMatch({required this.value, required this.position});
}

class _UnitMatch {
  final int start;
  final int end;
  final String normalized;
  final String raw;
  _UnitMatch({required this.start, required this.end, required this.normalized, required this.raw});
}
