import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:court_ocr_scanner/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Court OCR Scanner app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const CourtOcrApp());
    await tester.pump();

    expect(find.text('Court OCR Scanner'), findsOneWidget);
    expect(find.text('Scan a document or open an existing Excel register.'), findsOneWidget);
  });
}
