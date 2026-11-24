import 'package:flutter_test/flutter_test.dart';
import 'package:cricyy/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const CricyyApp());
    await tester.pumpAndSettle();
    expect(find.text('Cricyy'), findsWidgets);
  });
}
