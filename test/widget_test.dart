import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Court OCR Scanner app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const CourtOcrApp());
    await tester.pump();

    expect(find.text('Court OCR Scanner'), findsWidgets);
    expect(find.text('Scan document'), findsOneWidget);
    expect(find.text('Save / Export Excel'), findsOneWidget);
  });
}
