import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the user has completed the health-profile onboarding in this
/// session.
///
/// This is intentionally in-memory only. Returning users are identified by
/// their active Supabase session ([isAuthenticatedProvider]) and bypass
/// onboarding automatically.
final onboardingCompleteProvider = StateProvider<bool>((ref) => false);
