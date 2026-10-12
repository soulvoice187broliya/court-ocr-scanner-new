import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  testWidgets('Court OCR Scanner app starts',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CourtOcrApp());

    expect(find.text('Court OCR Scanner'), findsWidgets);
  });
}
