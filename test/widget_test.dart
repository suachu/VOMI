import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vomi/views/auth/pages/landing_page.dart';

void main() {
  testWidgets('Landing page renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LandingPage(),
      ),
    );
    await tester.pump();

    expect(find.byType(LandingPage), findsOneWidget);
  });
}
