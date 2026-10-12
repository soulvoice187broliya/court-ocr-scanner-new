import 'package:flutter_test/flutter_test.dart';
import 'package:court_ocr_scanner/main.dart';

void main() {
  testWidgets('Court OCR Scanner app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const CourtOcrScannerApp());

    expect(find.text('Court OCR Scanner'), findsOneWidget);
  });
}
