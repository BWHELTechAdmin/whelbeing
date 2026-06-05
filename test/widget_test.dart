// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';

import 'package:whelbeing/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WhelbeingApp());

    // Verify that the Learn screen is displayed by default.
    expect(find.text('Learn'), findsWidgets);
  });
}
