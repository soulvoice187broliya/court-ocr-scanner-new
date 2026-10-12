import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  group('date helpers', () {
    test('formats dates as DD/MM/YYYY', () {
      expect(fmtDate(DateTime(2026, 10, 9)), '09/10/2026');
    });

    test('converts scan date to month and year', () {
      expect(monthYear('09/10/2026'), 'Oct2026');
    });

    test('returns empty month/year for invalid dates', () {
      expect(monthYear('31/13/2026'), isEmpty);
      expect(monthYear('not a date'), isEmpty);
    });
  });
}
