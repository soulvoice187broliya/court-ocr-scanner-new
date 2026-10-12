import 'package:flutter_test/flutter_test.dart';
import 'package:court_ocr_scanner/main.dart';

void main() {
  group('Date Helpers', () {
    test('fmtDate formats date as DD/MM/YYYY', () {
      expect(fmtDate(DateTime(2026, 9, 19)), '19/09/2026');
    });

    test('monthYear converts a valid date to abbreviated month and year', () {
      expect(monthYear('19/09/2026'), 'Sep2026');
    });

    test('monthYear rejects invalid month', () {
      expect(monthYear('19/13/2026'), isEmpty);
    });

    test('monthYear rejects invalid day', () {
      expect(monthYear('31/09/2026'), isEmpty);
    });

    test('monthYear rejects invalid year', () {
      expect(monthYear('19/09/abcd'), isEmpty);
    });

    test('monthYear rejects invalid date format', () {
      expect(monthYear('not a date'), isEmpty);
    });

    test('monthYear rejects empty input', () {
      expect(monthYear(''), isEmpty);
    });
  });
}