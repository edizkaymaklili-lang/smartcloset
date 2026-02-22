import 'package:flutter_test/flutter_test.dart';
import 'package:stil_asist/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StilAsistApp());
    expect(find.text('Stil Asist'), findsWidgets);
  });
}
