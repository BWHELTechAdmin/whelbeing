import 'package:flutter/widgets.dart' show Size, Widget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whelbeing/main.dart';
import 'package:whelbeing/providers/auth_provider.dart';
import 'package:whelbeing/services/auth_callback_handler.dart';

void main() {
  Widget buildApp({
    SignedOutEntry entry = SignedOutEntry.onboarding,
    String? pendingVerificationEmail,
    AuthCallbackState callbackState = const AuthCallbackState(),
  }) {
    final handler = AuthCallbackHandler();
    handler.state.value = callbackState;
    return ProviderScope(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => Stream.empty()),
        isAuthenticatedProvider.overrideWith((ref) => false),
        isEmailVerifiedProvider.overrideWith((ref) => false),
        hasCompletedOnboardingProvider.overrideWith((ref) => false),
        currentSessionProvider.overrideWith((ref) => null),
        signedOutEntryProvider.overrideWith((ref) => entry),
        pendingEmailVerificationProvider.overrideWith(
          (ref) => pendingVerificationEmail,
        ),
        authCallbackHandlerProvider.overrideWithValue(handler),
      ],
      child: const WhelbeingApp(),
    );
  }

  testWidgets('signed-out users enter through sign-in', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildApp(entry: SignedOutEntry.signIn));

    expect(find.text('Welcome\nback.'), findsOneWidget);
  });

  testWidgets('unconfirmed sign-in is routed to verification', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      buildApp(pendingVerificationEmail: 'member@example.com'),
    );

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.text('Resend verification email'), findsOneWidget);
  });

  testWidgets('expired recovery callback shows a recoverable error', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      buildApp(
        callbackState: const AuthCallbackState(
          kind: AuthCallbackKind.passwordRecovery,
          errorMessage: 'This reset link has expired or has already been used.',
        ),
      ),
    );

    expect(find.text('Return to sign in'), findsOneWidget);
  });
}
