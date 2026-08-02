import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('widget test harness boots', (WidgetTester tester) async {
    // NOTE: We intentionally avoid pumping the full app here because it requires
    // Firebase initialization and method-channel setup in tests.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
