// lib/services/gst_classifier.dart
// Auto-classifies items by name → GST rate (0%, 5%, 12%, 18%, 28%)

class GstClassifier {
  static const Map<String, int> _itemToRate = {
    // 0% — Essential foods
    'rice': 0, 'wheat': 0, 'flour': 0, 'atta': 0, 'maida': 0,
    'milk': 0, 'curd': 0, 'paneer': 0, 'butter': 0, 'ghee': 0,
    'salt': 0, 'sugar': 0, 'jaggery': 0, 'gur': 0,
    'dal': 0, 'pulses': 0, 'chana': 0, 'moong': 0, 'urad': 0,
    'fruits': 0, 'fruit': 0, 'apple': 0, 'banana': 0, 'orange': 0,
    'mango': 0, 'grapes': 0, 'watermelon': 0, 'papaya': 0,
    'guava': 0, 'pineapple': 0, 'pomegranate': 0, 'lemon': 0,
    'vegetables': 0, 'onion': 0, 'potato': 0, 'tomato': 0, 'carrot': 0,
    'spinach': 0, 'cabbage': 0, 'cauliflower': 0, 'brinjal': 0,
    'fresh meat': 0, 'fresh fish': 0, 'fresh egg': 0, 'eggs': 0,
    'newspaper': 0, 'books': 0, 'textbook': 0,

    // 5% — Basic necessities
    'tea': 5, 'coffee': 5, 'spices': 5, 'masala': 5,
    'edible oil': 5, 'oil': 5, 'cooking oil': 5,
    'biscuit': 5, 'bread': 5, 'rusk': 5,
    'medicine': 5, 'medicines': 5, 'tablet': 5, 'syrup': 5,
    'footwear': 5, 'sandal': 5, 'slipper': 5, 'shoe': 5,
    'clothes': 5, 'cotton': 5, 'saree': 5, 'fabric': 5,
    'kerosene': 5, 'lpg': 5, 'coal': 5,

    // 12% — Standard goods
    'mobile': 12, 'phone': 12, 'smartphone': 12, 'charger': 12,
    'cheese': 12, 'juice': 12, 'fruit juice': 12,
    'sausage': 12, 'condensed milk': 12,
    'umbrella': 12, 'bicycle': 12, 'cycle': 12,
    'spectacles': 12, 'frozen meat': 12, 'pickle': 12, 'jam': 12,

    // 18% — Most goods/services
    'soap': 18, 'shampoo': 18, 'toothpaste': 18, 'detergent': 18,
    'hair oil': 18, 'lotion': 18, 'cosmetic': 18, 'perfume': 18,
    'tissue': 18, 'cake': 18, 'pastry': 18, 'chocolate': 18,
    'sweets': 18, 'mithai': 18, 'ice cream': 18,
    'cornflakes': 18, 'pasta': 18, 'noodles': 18, 'maggi': 18,
    'computer': 18, 'laptop': 18, 'printer': 18, 'monitor': 18,
    'keyboard': 18, 'mouse': 18, 'speaker': 18, 'headphone': 18,
    'television': 18, 'tv': 18, 'led tv': 18,
    'refrigerator': 18, 'fridge': 18, 'washing machine': 18,
    'fan': 18, 'cooler': 18, 'mixer': 18, 'grinder': 18,
    'oven': 18, 'microwave': 18, 'iron': 18,
    'furniture': 18, 'chair': 18, 'table': 18, 'sofa': 18, 'bed': 18,
    'mattress': 18, 'cupboard': 18, 'wardrobe': 18,
    'cement': 18, 'tiles': 18, 'paint': 18, 'plywood': 18,
    'steel': 18, 'iron rod': 18, 'pipes': 18,
    'bag': 18, 'wallet': 18, 'belt': 18, 'watch': 18,
    'pen': 18, 'pencil': 18, 'notebook': 18, 'paper': 18,
    'helmet': 18, 'tyre': 18, 'battery': 18,
    'service': 18, 'consultancy': 18, 'design': 18, 'development': 18,
    'repair': 18, 'maintenance': 18, 'installation': 18,

    // 28% — Luxury / Sin
    'car': 28, 'motorcycle': 28, 'bike': 28, 'scooter': 28,
    'air conditioner': 28, 'ac': 28, 'split ac': 28,
    'cigarette': 28, 'tobacco': 28, 'pan masala': 28, 'gutkha': 28,
    'soft drinks': 28, 'cola': 28, 'pepsi': 28, 'coke': 28,
    'energy drinks': 28, 'lottery': 28, 'casino': 28,
  };

  /// Returns matching GST rate (0/5/12/18/28) or -1 if no match.
  static int classify(String itemName) {
    final lower = itemName.toLowerCase().trim();
    if (lower.isEmpty) return -1;

    if (_itemToRate.containsKey(lower)) return _itemToRate[lower]!;

    final words = lower.split(RegExp(r'\s+'));
    for (final word in words) {
      if (_itemToRate.containsKey(word)) return _itemToRate[word]!;
    }

    for (final entry in _itemToRate.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }

    return -1;
  }

  static String categoryFor(int rate) {
    switch (rate) {
      case 0: return 'Essential / Tax-free';
      case 5: return 'Basic necessities';
      case 12: return 'Standard goods';
      case 18: return 'General goods & services';
      case 28: return 'Luxury / Sin goods';
      default: return 'General';
    }
  }
}
