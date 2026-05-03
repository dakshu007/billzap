// lib/utils/festival_data.dart
// Festival database for India: dates 2026-2027 + multi-language message templates.
//
// Covers ~16 major festivals: pan-Indian (Diwali, Holi, Eid, Christmas, etc.)
// + regional (Pongal/TN, Onam/Kerala, Ugadi/AP-KA, Baisakhi/PB).
//
// Each festival has: name, emoji, date, optional region tag, and message templates
// in 12 supported languages (English + 11 Indian languages).
//
// Dates verified from timeanddate.com, drikpanchang.com, India Government calendar
// for 2026. 2027 dates are best-estimates that should be re-verified before that year.

import 'package:intl/intl.dart';

class Festival {
  final String id;            // 'diwali', 'holi', etc.
  final String name;          // Display name
  final String emoji;
  final DateTime date;
  final String? region;       // null = pan-Indian. else: 'TN', 'KL', 'PB', etc.
  final String defaultMessage;  // English fallback
  final Map<String, String> messages;  // language code → message

  const Festival({
    required this.id,
    required this.name,
    required this.emoji,
    required this.date,
    this.region,
    required this.defaultMessage,
    this.messages = const {},
  });

  String messageFor(String langCode) {
    return messages[langCode] ?? defaultMessage;
  }

  /// Days from now to this festival. Negative = past.
  int daysFromToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final festDay = DateTime(date.year, date.month, date.day);
    return festDay.difference(today).inDays;
  }

  bool get isToday => daysFromToday() == 0;
  bool get isTomorrow => daysFromToday() == 1;
  bool get isUpcoming => daysFromToday() >= 0 && daysFromToday() <= 1;
}

class FestivalData {
  // Use {biz} placeholder for business name
  static final List<Festival> _all = [
    // ─────────── 2026 ───────────
    Festival(
      id: 'newyear_2026',
      name: 'New Year',
      emoji: '🎊',
      date: DateTime(2026, 1, 1),
      defaultMessage:
        'Wishing you a happy and prosperous New Year! 🎊\nMay 2026 bring success and joy.\n\n— {biz}',
      messages: {
        'hi': 'नया साल मुबारक हो! 🎊\nयह साल आपके लिए सफलता और खुशियाँ लाए।\n\n— {biz}',
        'ta': 'புத்தாண்டு வாழ்த்துக்கள்! 🎊\nஇந்த ஆண்டு உங்களுக்கு வெற்றியும் மகிழ்ச்சியும் கொண்டு வரட்டும்.\n\n— {biz}',
        'te': 'నూతన సంవత్సర శుభాకాంక్షలు! 🎊\nఈ సంవత్సరం మీకు విజయం మరియు ఆనందం తెచ్చుగాక.\n\n— {biz}',
      },
    ),
    Festival(
      id: 'pongal_2026',
      name: 'Pongal',
      emoji: '🌾',
      date: DateTime(2026, 1, 14),
      region: 'TN',
      defaultMessage:
        'Happy Pongal! 🌾\nMay this harvest festival bring prosperity to your home and business.\n\n— {biz}',
      messages: {
        'ta': 'பொங்கல் வாழ்த்துக்கள்! 🌾\nஇந்த அறுவடை திருநாள் உங்கள் வீட்டிலும் வியாபாரத்திலும் செழிப்பைக் கொண்டு வரட்டும்.\n\n— {biz}',
        'hi': 'पोंगल की हार्दिक शुभकामनाएं! 🌾\nयह फसल का त्योहार आपके घर और व्यवसाय में समृद्धि लाए।\n\n— {biz}',
      },
    ),
    Festival(
      id: 'republicday_2026',
      name: 'Republic Day',
      emoji: '🇮🇳',
      date: DateTime(2026, 1, 26),
      defaultMessage:
        'Happy Republic Day! 🇮🇳\nWishing you and your family a proud and peaceful day.\n\n— {biz}',
      messages: {
        'hi': 'गणतंत्र दिवस की हार्दिक शुभकामनाएं! 🇮🇳\nजय हिंद!\n\n— {biz}',
        'ta': 'குடியரசு தினம் வாழ்த்துக்கள்! 🇮🇳\nஜெய் ஹிந்த்!\n\n— {biz}',
      },
    ),
    Festival(
      id: 'holi_2026',
      name: 'Holi',
      emoji: '🎨',
      date: DateTime(2026, 3, 4),
      defaultMessage:
        'Happy Holi! 🎨\nWishing you a colourful and joyful festival.\nMay your life be filled with the colours of love and happiness.\n\n— {biz}',
      messages: {
        'hi': 'होली की हार्दिक शुभकामनाएं! 🎨\nआपके जीवन में खुशियों के रंग भरें।\n\n— {biz}',
        'ta': 'ஹோலி நல்வாழ்த்துக்கள்! 🎨\nஉங்கள் வாழ்க்கை வண்ணமயமாக இருக்கட்டும்.\n\n— {biz}',
        'mr': 'होळीच्या हार्दिक शुभेच्छा! 🎨\nतुमचे आयुष्य रंगांनी भरून जावो.\n\n— {biz}',
      },
    ),
    Festival(
      id: 'tamilnewyear_2026',
      name: 'Tamil New Year',
      emoji: '🌸',
      date: DateTime(2026, 4, 14),
      region: 'TN',
      defaultMessage:
        'Happy Tamil New Year! 🌸\nWishing you and your family success and prosperity.\n\n— {biz}',
      messages: {
        'ta': 'தமிழ் புத்தாண்டு வாழ்த்துக்கள்! 🌸\nஉங்களுக்கும் உங்கள் குடும்பத்திற்கும் வெற்றியும் செழிப்பும் கிட்டட்டும்.\n\n— {biz}',
      },
    ),
    Festival(
      id: 'baisakhi_2026',
      name: 'Baisakhi',
      emoji: '🌾',
      date: DateTime(2026, 4, 14),
      region: 'PB',
      defaultMessage:
        'Happy Baisakhi! 🌾\nWishing you a year full of joy, prosperity, and success.\n\n— {biz}',
      messages: {
        'pa': 'ਵਿਸਾਖੀ ਦੀਆਂ ਮੁਬਾਰਕਾਂ! 🌾\nਨਵਾਂ ਸਾਲ ਖੁਸ਼ੀਆਂ ਨਾਲ ਭਰਪੂਰ ਹੋਵੇ।\n\n— {biz}',
        'hi': 'बैसाखी की शुभकामनाएं! 🌾\n\n— {biz}',
      },
    ),
    Festival(
      id: 'eidulfitr_2026',
      name: 'Eid ul-Fitr',
      emoji: '🌙',
      date: DateTime(2026, 3, 21), // approximate, depends on moon sighting
      defaultMessage:
        'Eid Mubarak! 🌙\nMay this Eid bring peace, happiness, and prosperity to your family.\n\n— {biz}',
      messages: {
        'hi': 'ईद मुबारक! 🌙\nयह ईद आपके लिए खुशियाँ और बरकत लाए।\n\n— {biz}',
        'ur': 'عید مبارک! 🌙\nاللہ آپ کو خوشیاں اور برکتیں نصیب فرمائے۔\n\n— {biz}',
      },
    ),
    Festival(
      id: 'independenceday_2026',
      name: 'Independence Day',
      emoji: '🇮🇳',
      date: DateTime(2026, 8, 15),
      defaultMessage:
        'Happy Independence Day! 🇮🇳\nProud to be Indian. Wishing you a happy day with family.\n\n— {biz}',
      messages: {
        'hi': 'स्वतंत्रता दिवस की हार्दिक शुभकामनाएं! 🇮🇳\nजय हिंद!\n\n— {biz}',
        'ta': 'சுதந்திர தின வாழ்த்துக்கள்! 🇮🇳\nஜெய் ஹிந்த்!\n\n— {biz}',
      },
    ),
    Festival(
      id: 'onam_2026',
      name: 'Onam',
      emoji: '🌺',
      date: DateTime(2026, 8, 26),
      region: 'KL',
      defaultMessage:
        'Happy Onam! 🌺\nWishing you a colourful festival full of joy and abundance.\n\n— {biz}',
      messages: {
        'ml': 'ഓണാശംസകൾ! 🌺\nനിങ്ങൾക്കും കുടുംബത്തിനും സന്തോഷകരമായ ഓണം ആശംസിക്കുന്നു.\n\n— {biz}',
      },
    ),
    Festival(
      id: 'rakshabandhan_2026',
      name: 'Raksha Bandhan',
      emoji: '🪢',
      date: DateTime(2026, 8, 28),
      defaultMessage:
        'Happy Raksha Bandhan! 🪢\nWishing your family love and togetherness.\n\n— {biz}',
      messages: {
        'hi': 'रक्षाबंधन की हार्दिक शुभकामनाएं! 🪢\nभाई-बहन के प्यार से भरा त्योहार आपके परिवार में खुशियाँ लाए।\n\n— {biz}',
      },
    ),
    Festival(
      id: 'janmashtami_2026',
      name: 'Janmashtami',
      emoji: '🪈',
      date: DateTime(2026, 9, 4),
      defaultMessage:
        'Happy Janmashtami! 🪈\nMay Lord Krishna bless you and your family.\n\n— {biz}',
      messages: {
        'hi': 'जन्माष्टमी की हार्दिक शुभकामनाएं! 🪈\nभगवान कृष्ण आप पर अपनी कृपा बनाए रखें।\n\n— {biz}',
        'ta': 'கிருஷ்ண ஜெயந்தி வாழ்த்துக்கள்! 🪈\n\n— {biz}',
      },
    ),
    Festival(
      id: 'ganeshchaturthi_2026',
      name: 'Ganesh Chaturthi',
      emoji: '🐘',
      date: DateTime(2026, 9, 14),
      defaultMessage:
        'Ganpati Bappa Morya! 🐘\nMay Lord Ganesha bring success, wisdom and prosperity to your business.\n\n— {biz}',
      messages: {
        'hi': 'गणपति बप्पा मोरया! 🐘\nभगवान गणेश आपके व्यवसाय में सफलता और समृद्धि लाएं।\n\n— {biz}',
        'mr': 'गणपती बाप्पा मोरया! 🐘\nगणेशजी तुमच्या व्यवसायात यश आणि समृद्धी आणोत.\n\n— {biz}',
      },
    ),
    Festival(
      id: 'gandhijayanti_2026',
      name: 'Gandhi Jayanti',
      emoji: '🕊️',
      date: DateTime(2026, 10, 2),
      defaultMessage:
        'Remembering Mahatma Gandhi today. 🕊️\nMay his ideals of truth and peace guide us all.\n\n— {biz}',
      messages: {
        'hi': 'गांधी जयंती की शुभकामनाएं। 🕊️\nबापू के विचार हमें हमेशा प्रेरित करते रहें।\n\n— {biz}',
      },
    ),
    Festival(
      id: 'navratri_2026',
      name: 'Navratri',
      emoji: '💃',
      date: DateTime(2026, 10, 11),
      defaultMessage:
        'Happy Navratri! 💃\nMay Maa Durga shower her blessings on you and your family.\n\n— {biz}',
      messages: {
        'hi': 'नवरात्रि की हार्दिक शुभकामनाएं! 💃\nमाँ दुर्गा आप पर अपनी कृपा बनाए रखें।\n\n— {biz}',
        'gu': 'નવરાત્રિની હાર્દિક શુભકામનાઓ! 💃\nમા દુર્ગા તમારા પર આશીર્વાદ વરસાવે.\n\n— {biz}',
      },
    ),
    Festival(
      id: 'dussehra_2026',
      name: 'Dussehra',
      emoji: '🏹',
      date: DateTime(2026, 10, 19),
      defaultMessage:
        'Happy Dussehra! 🏹\nMay good triumph over evil in your life. Wishing you success.\n\n— {biz}',
      messages: {
        'hi': 'दशहरे की हार्दिक शुभकामनाएं! 🏹\nबुराई पर अच्छाई की जीत हो।\n\n— {biz}',
      },
    ),
    Festival(
      id: 'diwali_2026',
      name: 'Diwali',
      emoji: '🪔',
      date: DateTime(2026, 11, 8),
      defaultMessage:
        '🪔 Happy Diwali!\n\nWishing you and your family a Diwali full of light, joy, and prosperity.\nMay Goddess Lakshmi bless your home and business.\n\n— {biz}',
      messages: {
        'hi': '🪔 दीपावली की हार्दिक शुभकामनाएं!\n\nयह दिवाली आपके घर में सुख, समृद्धि और खुशियाँ लाए।\nमाँ लक्ष्मी आप पर अपनी कृपा बनाए रखें।\n\n— {biz}',
        'ta': '🪔 தீபாவளி நல்வாழ்த்துக்கள்!\n\nஇந்த தீபாவளி உங்கள் வீட்டிலும் வியாபாரத்திலும் ஒளியும் செழிப்பும் கொண்டு வரட்டும்.\n\n— {biz}',
        'te': '🪔 దీపావళి శుభాకాంక్షలు!\n\nఈ దీపావళి మీ ఇంటిలో మరియు వ్యాపారంలో వెలుగు తెచ్చుగాక.\n\n— {biz}',
        'mr': '🪔 दिवाळीच्या हार्दिक शुभेच्छा!\n\nहा दिवाळी सण तुमच्या घरात आणि व्यवसायात समृद्धी आणो.\n\n— {biz}',
        'gu': '🪔 દિવાળીની હાર્દિક શુભકામનાઓ!\n\nઆ દિવાળી તમારા ઘરમાં અને ધંધામાં સમૃદ્ધિ લાવે.\n\n— {biz}',
        'kn': '🪔 ದೀಪಾವಳಿಯ ಶುಭಾಶಯಗಳು!\n\nಈ ದೀಪಾವಳಿ ನಿಮ್ಮ ಮನೆ ಮತ್ತು ವ್ಯಾಪಾರಕ್ಕೆ ಸಮೃದ್ಧಿ ತರಲಿ.\n\n— {biz}',
        'ml': '🪔 ദീപാവലി ആശംസകൾ!\n\nഈ ദീപാവലി നിങ്ങളുടെ വീട്ടിലും ബിസിനസിലും സമൃദ്ധി കൊണ്ടുവരട്ടെ.\n\n— {biz}',
        'bn': '🪔 শুভ দীপাবলি!\n\nএই দীপাবলি আপনার ঘরে ও ব্যবসায় সমৃদ্ধি বয়ে আনুক।\n\n— {biz}',
        'pa': '🪔 ਦੀਵਾਲੀ ਦੀਆਂ ਮੁਬਾਰਕਾਂ!\n\nਇਹ ਦੀਵਾਲੀ ਤੁਹਾਡੇ ਘਰ ਅਤੇ ਕਾਰੋਬਾਰ ਵਿੱਚ ਖੁਸ਼ਹਾਲੀ ਲਿਆਵੇ।\n\n— {biz}',
        'or': '🪔 ଶୁଭ ଦୀପାବଳି!\n\n— {biz}',
        'ur': '🪔 دیوالی مبارک!\n\nیہ دیوالی آپ کے گھر اور کاروبار میں خوشیاں لائے۔\n\n— {biz}',
      },
    ),
    Festival(
      id: 'christmas_2026',
      name: 'Christmas',
      emoji: '🎄',
      date: DateTime(2026, 12, 25),
      defaultMessage:
        'Merry Christmas! 🎄\nWishing you and your family joy, peace, and good cheer this season.\n\n— {biz}',
      messages: {
        'hi': 'क्रिसमस की हार्दिक शुभकामनाएं! 🎄\n\n— {biz}',
        'ta': 'கிறிஸ்துமஸ் வாழ்த்துக்கள்! 🎄\n\n— {biz}',
        'ml': 'ക്രിസ്‌മസ്‌ ആശംസകൾ! 🎄\n\n— {biz}',
      },
    ),

    // ─────────── 2027 (best estimates, may need refresh) ───────────
    Festival(
      id: 'newyear_2027',
      name: 'New Year',
      emoji: '🎊',
      date: DateTime(2027, 1, 1),
      defaultMessage:
        'Wishing you a happy and prosperous New Year! 🎊\n\n— {biz}',
    ),
    Festival(
      id: 'pongal_2027',
      name: 'Pongal',
      emoji: '🌾',
      date: DateTime(2027, 1, 14),
      region: 'TN',
      defaultMessage:
        'Happy Pongal! 🌾\nMay this harvest festival bring prosperity.\n\n— {biz}',
    ),
    Festival(
      id: 'republicday_2027',
      name: 'Republic Day',
      emoji: '🇮🇳',
      date: DateTime(2027, 1, 26),
      defaultMessage:
        'Happy Republic Day! 🇮🇳\nJai Hind!\n\n— {biz}',
    ),
    Festival(
      id: 'holi_2027',
      name: 'Holi',
      emoji: '🎨',
      date: DateTime(2027, 3, 22),
      defaultMessage:
        'Happy Holi! 🎨\nMay your life be filled with colours of joy.\n\n— {biz}',
    ),
    Festival(
      id: 'independenceday_2027',
      name: 'Independence Day',
      emoji: '🇮🇳',
      date: DateTime(2027, 8, 15),
      defaultMessage:
        'Happy Independence Day! 🇮🇳\nJai Hind!\n\n— {biz}',
    ),
    Festival(
      id: 'diwali_2027',
      name: 'Diwali',
      emoji: '🪔',
      date: DateTime(2027, 10, 28),
      defaultMessage:
        '🪔 Happy Diwali!\nWishing you light, joy and prosperity.\n\n— {biz}',
    ),
    Festival(
      id: 'christmas_2027',
      name: 'Christmas',
      emoji: '🎄',
      date: DateTime(2027, 12, 25),
      defaultMessage:
        'Merry Christmas! 🎄\nWishing you joy and peace this season.\n\n— {biz}',
    ),
  ];

  /// Get the festival to show on the dashboard banner today.
  /// Returns the closest upcoming festival within 1 day window, null otherwise.
  /// If user has a state code, regional festivals are filtered.
  static Festival? upcoming({String? userStateCode}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter to relevant festivals
    final relevant = _all.where((f) {
      // Skip past festivals
      final festDate = DateTime(f.date.year, f.date.month, f.date.day);
      final diff = festDate.difference(today).inDays;
      if (diff < 0 || diff > 1) return false;

      // Filter by region if applicable
      if (f.region != null && userStateCode != null && userStateCode.isNotEmpty) {
        // Show pan-India + matching region only
        return f.region == userStateCode;
      }
      // Pan-India festival OR no region info from user
      return true;
    }).toList();

    if (relevant.isEmpty) return null;

    // Sort by closest first
    relevant.sort((a, b) => a.daysFromToday().compareTo(b.daysFromToday()));
    return relevant.first;
  }

  /// Get all upcoming festivals in the next N days (for "what's coming" view)
  static List<Festival> upcomingInNext(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _all.where((f) {
      final festDate = DateTime(f.date.year, f.date.month, f.date.day);
      final diff = festDate.difference(today).inDays;
      return diff >= 0 && diff <= days;
    }).toList()
      ..sort((a, b) => a.daysFromToday().compareTo(b.daysFromToday()));
  }

  /// Get a festival by id
  static Festival? byId(String id) {
    try {
      return _all.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }
}
