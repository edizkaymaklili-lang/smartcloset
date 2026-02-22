import 'package:flutter_test/flutter_test.dart';
import 'package:stil_asist/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartClosetApp());
    expect(find.text('Smart Closet'), findsWidgets);
  });
}
