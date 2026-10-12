import 'package:flutter_test/flutter_test.dart';
import 'package:court_ocr_scanner/main.dart';

void main() {
  group('date helpers', () {
    test('fmtDate uses DD/MM/YYYY', () {
      expect(fmtDate(DateTime(2026, 9, 19)), '19/09/2026');
    });

    test('monthYear converts a valid date to abbreviated month and year', () {
      expect(monthYear('19/09/2026'), 'Sep2026');
    });

    test('monthYear rejects invalid dates', () {
      expect(monthYear('31/13/2026'), isEmpty);
      expect(monthYear('not a date'), isEmpty);
    });
  });
}
