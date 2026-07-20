import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/learn_screen.dart';
import 'utils/size_config.dart';
import 'screens/home_screen.dart';
import 'screens/track_screen.dart';
import 'screens/onboarding_screen.dart';
import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/health_record_provider.dart';
import 'providers/onboarding_provider.dart';
import 'repositories/auth_repository.dart';
import 'services/biometric_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  // Load the biometric setting before runApp so _BiometricGuard can read it
  // synchronously on the first frame without any async gap.
  await BiometricSettings.init();
  runApp(const ProviderScope(child: WhelbeingApp()));
}

class WhelbeingApp extends StatelessWidget {
  const WhelbeingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whelbeing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFC9A96E), // Muted gold
          secondary: const Color(0xFF6B5220), // Dark warm gold
          surface: const Color(0xFF1A1A1A),
          onPrimary: Colors.white,
          onSurface: const Color(0xFFE8DCC8), // Warm cream
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D0D0D),
          foregroundColor: Color(0xFFE8DCC8),
          elevation: 0,
        ),
        dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1A1A1A)),
      ),
      home: const _AppEntry(),
    );
  }
}

// ─── App entry (onboarding → main nav) ──────────────────────────────────────

/// Root widget that decides between [HealthProfileOnboarding] and
/// [MainNavigation] based on Supabase auth state and onboarding progress.
///
/// Both decisions are driven by Riverpod providers, so no [StreamSubscription]
/// or [setState] boilerplate is needed here.
class _AppEntry extends ConsumerWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    // Record today as an active day whenever a session starts.
    // AuthChangeEvent.initialSession fires on app start with existing session;
    // AuthChangeEvent.signedIn fires after the user signs in interactively.
    ref.listen<AsyncValue<AuthState>>(authStateChangesProvider, (_, state) {
      final event = state.valueOrNull?.event;
      if (event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.signedIn) {
        ref
            .read(authRepositoryProvider)
            .recordAppOpen()
            .then((_) => ref.invalidate(streakProvider))
            .ignore();
      }
      // Clear the local onboarding flag so _AppEntry routes back to the
      // sign-in / onboarding screen rather than staying on MainNavigation.
      if (event == AuthChangeEvent.signedOut) {
        ref.read(onboardingCompleteProvider.notifier).state = false;
      }
    });
    // Persisted flag — true only if the user has previously finished onboarding
    // on any device (stored in Supabase user metadata).
    final persistedComplete = ref.watch(hasCompletedOnboardingProvider);
    // Local flag — set this session after the user taps "Enter BWhel".
    // Used to navigate immediately without waiting for the Supabase write.
    final localComplete = ref.watch(onboardingCompleteProvider);

    // Go to the main app only when we KNOW onboarding is done:
    //   (a) Returning user — authenticated + persisted flag, OR
    //   (b) Just finished — local flag set this session (covers both
    //       authenticated users and users who skip sign-in entirely).
    if ((isAuthenticated && persistedComplete) || localComplete) {
      return const _BiometricGuard();
    }

    return HealthProfileOnboarding(
        isAlreadyAuthenticated: isAuthenticated,
        onComplete: () {
          // Best-effort persist to Supabase if the user is signed in.
          // Fire-and-forget — local flag handles navigation immediately;
          // hasCompletedOnboardingProvider refreshes once Supabase responds.
          if (ref.read(isAuthenticatedProvider)) {
            ref
                .read(authRepositoryProvider)
                .markOnboardingComplete()
                .ignore();
          }
          ref.read(onboardingCompleteProvider.notifier).state = true;
        },
      );
  }
}

// ─── Biometric guard ─────────────────────────────────────────────────────────

/// Wraps [MainNavigation] with biometric authentication.
///
/// When biometric lock is enabled in settings:
/// - Locks immediately on first mount (app opened with existing session).
/// - Locks whenever the app returns from background (paused → resumed).
///
/// The lock screen prompts biometrics automatically and exposes a "Try Again"
/// button for retry after cancellation or failure.
class _BiometricGuard extends StatefulWidget {
  const _BiometricGuard();

  @override
  State<_BiometricGuard> createState() => _BiometricGuardState();
}

class _BiometricGuardState extends State<_BiometricGuard>
    with WidgetsBindingObserver {
  // Initialised synchronously in initState so the very first build already
  // shows the lock screen — prevents a flash of app content before auth.
  late bool _isLocked;
  bool _isAuthenticating = false;
  bool _wentToBackground = false;

  @override
  void initState() {
    super.initState();
    _isLocked = BiometricSettings.enabled;
    WidgetsBinding.instance.addObserver(this);
    // Trigger the auth prompt after the lock screen is already visible.
    if (_isLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Both paused and hidden mean the app is no longer visible on iOS.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _wentToBackground = true;
    } else if (state == AppLifecycleState.resumed && _wentToBackground) {
      _wentToBackground = false;
      _lockIfEnabled();
    }
  }

  /// Locks the screen and triggers authentication if biometric is enabled.
  Future<void> _lockIfEnabled() async {
    if (!BiometricSettings.enabled) return;
    if (!mounted) return;
    setState(() => _isLocked = true);
    await _authenticate();
  }

  /// Runs the biometric prompt. Unlocks on success; keeps locked on failure
  /// so the user can retry via the lock screen button.
  Future<void> _authenticate() async {
    if (_isAuthenticating || !mounted) return;
    setState(() => _isAuthenticating = true);
    final success = await BiometricService.authenticate();
    if (!mounted) return;
    setState(() {
      _isAuthenticating = false;
      if (success) _isLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return _BiometricLockScreen(
        onRetry: _authenticate,
        isAuthenticating: _isAuthenticating,
      );
    }
    return const MainNavigation();
  }
}

/// Full-screen lock overlay shown when biometric authentication is required.
class _BiometricLockScreen extends StatelessWidget {
  const _BiometricLockScreen({
    required this.onRetry,
    required this.isAuthenticating,
  });

  final VoidCallback onRetry;
  final bool isAuthenticating;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFC9A96E).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.fingerprint,
                    size: 44,
                    color: Color(0xFFC9A96E),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Authentication Required',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE8DCC8),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Use your biometrics or device passcode\nto access Whelbeing',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                if (isAuthenticating)
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFFC9A96E),
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.fingerprint, size: 20),
                    label: const Text('Try Again'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC9A96E),
                      foregroundColor: const Color(0xFF0D0D0D),
                      minimumSize: const Size(180, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Main navigation shell ────────────────────────────────────────────────────

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1;

  final List<Widget> _screens = [
    const LearnScreen(),
    const HomeScreen(),
    const TrackScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Scaffold(
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        height: 7 * vh,
        margin: EdgeInsets.symmetric(horizontal: 18.0 * vw, vertical: 2.0 * vh),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(7.5 * vw),
          border: Border.all(color: const Color(0xFF2A2520).withValues(alpha: 0.5)),
        ),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7.5 * vw),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(navigationBarTheme: const NavigationBarThemeData()),
              child: Align(
                alignment: AlignmentGeometry.bottomCenter,
                child: MediaQuery.removePadding(context: context,
                removeBottom: true,
                removeTop: true,
                child:BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: const Color(0xFF1A1A1A),
                  selectedItemColor: const Color(0xFFC9A96E),
                  unselectedItemColor: const Color(0xFF5A5A5A),
                  selectedFontSize: 3.0 * vw,
                  unselectedFontSize: 3.0 * vw,
                  iconSize: 5.5 * vw,
                  elevation: 10,
                  selectedLabelStyle: const TextStyle(height: 1.0),
                  unselectedLabelStyle: const TextStyle(height: 1.0),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.book_outlined),
                      activeIcon: Icon(Icons.book),
                      label: 'Learn',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.favorite_outline),
                      activeIcon: Icon(Icons.favorite),
                      label: 'Track',
                    ),
                  ],
                ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
