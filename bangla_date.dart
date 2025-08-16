import 'package:intl/intl.dart';

class BanglaDate {
  final int year;
  final int month; // 1-12 (Boishakh=1 ... Chaitra=12)
  final int day;

  BanglaDate(this.year, this.month, this.day);

  static const List<String> monthNames = [
    'বৈশাখ', 'জ্যৈষ্ঠ', 'আষাঢ়', 'শ্রাবণ', 'ভাদ্র', 'আশ্বিন',
    'কার্তিক', 'অগ্রহায়ণ', 'পৌষ', 'মাঘ', 'ফাল্গুন', 'চৈত্র'
  ];

  String get monthName => monthNames[month - 1];
}

class BanglaDateConverter {
  /// Very small approximate converter for West Bengal reformed Bengali calendar.
  /// It maps a given Gregorian date to Bangla date.
  /// Rules (approx):
  /// - Poila Boishakh ≈ April 14.
  /// - Boishakh–Bhadra: 31 days, Ashwin–Chaitra: 30 days.
  /// - Chaitra gets 31 days on Gregorian leap year.
  /// We store ISO (Gregorian) and show Bangla for UI.
  static BanglaDate fromGregorian(DateTime g) {
    final int gYear = g.year;
    final bool isLeap = _isGregorianLeap(gYear);

    // Bengali months lengths (WB reformed approx)
    final List<int> monthLengths = [
      31, // Boishakh
      31, // Joishtho
      31, // Asharh
      31, // Srabon
      31, // Bhadro
      30, // Ashwin
      30, // Kartik
      30, // Agrahayan
      30, // Poush
      30, // Magh
      30, // Falgun
      isLeap ? 31 : 30, // Chaitra
    ];

    // Anchor Poila Boishakh on April 14
    final DateTime anchor = DateTime(gYear, 4, 14);
    int by = gYear - 593; // Rough offset between Gregorian and Bangla years

    Duration diff;
    if (g.isBefore(anchor)) {
      // Use previous year's anchor
      final DateTime prevAnchor = DateTime(gYear - 1, 4, 14);
      by = gYear - 594;
      diff = g.difference(prevAnchor);
    } else {
      diff = g.difference(anchor);
    }

    int days = diff.inDays; // 0-based from Poila Boishakh
    int bm = 0;
    while (bm < 12 && days >= monthLengths[bm]) {
      days -= monthLengths[bm];
      bm++;
    }
    int bd = days + 1;

    return BanglaDate(by, bm + 1, bd);
  }

  static bool _isGregorianLeap(int y) {
    if (y % 400 == 0) return true;
    if (y % 100 == 0) return false;
    return y % 4 == 0;
  }

  static String toBanglaDigits(String input) {
    const Map<String, String> map = {
      '0': '০','1': '১','2': '২','3': '৩','4': '৪',
      '5': '৫','6': '৬','7': '৭','8': '৮','9': '৯'
    };
    return input.split('').map((c) => map[c] ?? c).join();
  }

  static String formatBanglaDate(DateTime g) {
    final bd = fromGregorian(g);
    final d = NumberFormat('00').format(bd.day);
    final y = bd.year.toString();
    final str = '${bd.monthName} ${d}, ${y}';
    return toBanglaDigits(str);
  }
}