import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricyy/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CricyyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Cricyy'), findsWidgets);
  });
}
