// This is a basic Flutter widget test.

import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whelbeing/main.dart';
import 'package:whelbeing/providers/auth_provider.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.empty()),
          isAuthenticatedProvider.overrideWith((ref) => true),
          isEmailVerifiedProvider.overrideWith((ref) => true),
          hasCompletedOnboardingProvider.overrideWith((ref) => true),
        ],
        child: const WhelbeingApp(),
      ),
    );

    // Verify that a returning, authenticated user reaches main navigation.
    expect(find.text('Learn'), findsWidgets);
  });
}
