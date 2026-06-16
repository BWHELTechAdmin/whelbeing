import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/sign_in_provider.dart';
import '../repositories/profile_repository.dart';
import '../utils/size_config.dart';
import '../utils/validators.dart';
import 'sign_in_screen.dart';

// ─── Data model ──────────────────────────────────────────────────────────────

enum _StepType { singleSelect, multiSelect, textInput }

enum _ValidatorType { none, zipCode }

class _StepConfig {
  final int section;
  final String question;
  final String? subtitle;
  final _StepType type;
  final List<String> options;
  final List<String>? optionDescriptions;
  final bool optional;
  final int? maxSelections;
  final List<String> exclusiveOptions;

  /// The option label whose selection reveals an inline text field.
  final String? textFieldOption;

  /// Hint text for the inline or standalone text field.
  final String? textHint;

  /// When true, the standalone text field for [textInput] steps is multiline.
  final bool multilineText;

  /// Validator applied to this step's text input (empty = no validation).
  final _ValidatorType validatorType;

  /// Screen-level context header rendered above the question in italic gold.
  final String? heroText;

  /// Screen-level context subtext rendered below [heroText], above the question.
  final String? heroSubtext;

  /// Keyboard type for standalone text-input steps.
  final TextInputType? keyboardType;

  const _StepConfig({
    required this.section,
    required this.question,
    this.subtitle,
    required this.type,
    this.options = const [],
    this.optionDescriptions, // ignore: unused_element_parameter
    this.optional = false,
    this.maxSelections,
    this.exclusiveOptions = const [],
    this.textFieldOption, // ignore: unused_element_parameter
    this.textHint,
    this.multilineText = false, // ignore: unused_element_parameter
    this.validatorType = _ValidatorType.none,
    this.heroText,
    this.heroSubtext,
    this.keyboardType,
  });
}

// ─── Onboarding step ─────────────────────────────────────────────────────────

enum _OnboardingStep { intro, signUp, questions, activation }

// ─── Widget ─────────────────────────────────────────────────────────────────

class HealthProfileOnboarding extends ConsumerStatefulWidget {
  const HealthProfileOnboarding({
    super.key,
    required this.onComplete,
    required this.isAlreadyAuthenticated,
  });

  final VoidCallback onComplete;

  /// When true, skips the sign-up page and goes directly to health-profile
  /// questions. Set by [_AppEntry] when the user already has an active session.
  final bool isAlreadyAuthenticated;

  @override
  ConsumerState<HealthProfileOnboarding> createState() =>
      _HealthProfileOnboardingState();
}

class _HealthProfileOnboardingState extends ConsumerState<HealthProfileOnboarding> {
  late _OnboardingStep _step;
  int _currentStep = 0;
  final Map<int, dynamic> _answers = {};
  final Map<int, TextEditingController> _textControllers = {};
  late final PageController _pageController;

  // ─── Content ───────────────────────────────────────────────────────────────

  static const _sectionTitles = [
    'Identity',       // Screen 2
    'Experience',     // Screen 3
    'Your Needs',     // Screen 4
    'Real-Time',      // Screen 5
    'Health Context', // Screen 6
    'Privacy',        // Screen 7
  ];

  static final List<_StepConfig> _steps = [
    // ── Section 0: Identity (Screen 2) ───────────────────────────────────────
    // Step 0 — racial identity (optional, multi-select)
    const _StepConfig(
      section: 0,
      question: 'How do you identify?',
      subtitle:
          'So we can support you better\u2014only share what feels right.\n\n'
          'This helps us personalise your experience. '
          'Everything here is optional and never used to identify you.',
      type: _StepType.multiSelect,
      optional: true,
      exclusiveOptions: ['Prefer not to say'],
      options: [
        'Black / African American',
        'Afro-Caribbean',
        'African immigrant',
        'Multiracial',
        'Prefer not to say',
      ],
    ),
    // Step 1 — age range (optional)
    const _StepConfig(
      section: 0,
      question: "What's your age range?",
      type: _StepType.singleSelect,
      optional: true,
      options: ['18\u201324', '25\u201334', '35\u201344', '45\u201354', '55+'],
    ),
    // Step 2 — ZIP code (5-digit validation; backend stores first 3 digits only)
    const _StepConfig(
      section: 0,
      question: "What's your ZIP code?",
      subtitle:
          'Used only to understand community-level trends\u2014not to identify you.',
      type: _StepType.textInput,
      optional: true,
      textHint: '12345',
      validatorType: _ValidatorType.zipCode,
      keyboardType: TextInputType.number,
    ),
    // Step 3 — insurance type (optional)
    const _StepConfig(
      section: 0,
      question: 'What kind of insurance are you working with?',
      type: _StepType.singleSelect,
      optional: true,
      options: [
        'Medicaid',
        'Medicare',
        'Private insurance',
        'Uninsured',
        'Not sure',
      ],
    ),

    // ── Section 1: Experience (Screen 3) ─────────────────────────────────────
    // Step 4 — primary dismissal question
    const _StepConfig(
      section: 1,
      heroText: 'Be real with us\u2014how has healthcare felt lately?',
      question:
          'Have you ever felt dismissed or not taken seriously by a provider?',
      type: _StepType.singleSelect,
      optional: true,
      options: ['Yes', 'No', "I'm not sure"],
    ),
    // Step 5 — dismissal details
    // Conditional: navigation skips here when step 4 \u2260 'Yes'.
    const _StepConfig(
      section: 1,
      question: 'What did that look like for you?',
      subtitle: "You're not alone. Select all that apply.",
      type: _StepType.multiSelect,
      optional: true,
      options: [
        'My symptoms were brushed off',
        "I was told \"it's nothing\" but it didn't feel like nothing",
        'I was denied a test or treatment',
        'The visit felt rushed',
        "I didn't get clear answers",
        'I felt judged or stereotyped',
        'Other',
      ],
    ),
    // Step 6 — care type
    // Conditional: navigation skips here when step 4 \u2260 'Yes'.
    const _StepConfig(
      section: 1,
      question: 'What type of care was this?',
      type: _StepType.singleSelect,
      optional: true,
      options: [
        'Primary care',
        'OB/GYN',
        'Emergency room',
        'Mental health',
        'Specialist',
      ],
    ),

    // ── Section 2: Needs (Screen 4) ──────────────────────────────────────────
    // Step 7 — support needs (max 2)
    const _StepConfig(
      section: 2,
      question: 'What would feel most helpful for you right now?',
      subtitle: "We'll tailor your experience to this.",
      type: _StepType.multiSelect,
      optional: true,
      maxSelections: 2,
      options: [
        'Knowing what to ask my doctor',
        'Speaking up when something feels off',
        "Understanding what's happening in my care",
        'Keeping track of symptoms',
        'Knowing my rights as a patient',
      ],
    ),
    // Step 8 — support timing
    const _StepConfig(
      section: 2,
      question: 'When do you usually need the most support?',
      type: _StepType.singleSelect,
      optional: true,
      options: [
        'Before appointments',
        'During appointments',
        'After appointments',
        'Honestly\u2026all of it',
      ],
    ),

    // ── Section 3: Real-Time Hook (Screen 5) ─────────────────────────────────
    // Step 9 — real-time guidance interest
    const _StepConfig(
      section: 3,
      heroText: 'Imagine having support in the moment',
      heroSubtext:
          "If something doesn't feel right during a visit, we can help "
          'you respond right then and there.',
      question: 'Would you use real-time guidance during a doctor\'s visit?',
      type: _StepType.singleSelect,
      optional: true,
      options: ['Yes, absolutely', "I'd try it", 'Not sure yet'],
    ),

    // ── Section 4: Health Context (Screen 6) ─────────────────────────────────
    // Step 10 — health focus areas (controlled selections only)
    const _StepConfig(
      section: 4,
      question: 'What areas do you need more support in?',
      subtitle:
          'This is optional and helps us tailor your experience. '
          'Not stored as medical records.',
      type: _StepType.multiSelect,
      optional: true,
      exclusiveOptions: ['Prefer not to say'],
      options: [
        'Reproductive health education',
        'Understanding ongoing or unexplained symptoms',
        'Mental wellness support',
        'Heart health awareness',
        'Just trying to stay on top of my health',
        'Prefer not to say',
      ],
    ),

    // ── Section 5: Trust + Consent (Screen 7) ────────────────────────────────
    // Step 11 — data consent
    const _StepConfig(
      section: 5,
      heroText: 'Your story matters\u2014and it\u2019s protected.',
      heroSubtext:
          '\u2022 We do not store medical records or identifiable health data\n'
          '\u2022 Your responses are anonymised and grouped with others\n'
          '\u2022 We never sell your data\n'
          '\u2022 You can delete your data at any time',
      question:
          'Are you okay with your anonymised experiences being used to '
          'improve care for others?',
      type: _StepType.singleSelect,
      optional: true,
      options: ['Yes', 'No'],
    ),
  ];

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Authenticated users skip straight to questions; new users see the
    // intro splash first.
    _step = widget.isAlreadyAuthenticated
        ? _OnboardingStep.questions
        : _OnboardingStep.intro;
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  // ─── Profile persistence ───────────────────────────────────────────────────

  /// Fire-and-forget save of onboarding answers to `public.profiles`.
  /// Failures are swallowed — profile data is supplementary and should never
  /// block the user from entering the app.
  void _saveProfile() {
    ref
        .read(profileRepositoryProvider)
        .saveOnboardingProfile(
          racialIdentity: (_answers[0] as List?)?.cast<String>(),
          ageRange: _answers[1] as String?,
          zipCode: _textControllers[2]?.text.trim(),
          insuranceType: _answers[3] as String?,
          feltDismissed: _answers[4] as String?,
          dismissalExperiences: (_answers[5] as List?)?.cast<String>(),
          dismissalCareType: _answers[6] as String?,
          supportNeeds: (_answers[7] as List?)?.cast<String>(),
          supportTiming: _answers[8] as String?,
          realtimeInterest: _answers[9] as String?,
          healthAreas: (_answers[10] as List?)?.cast<String>(),
          dataConsent: _answers[11] as String?,
        )
        .ignore();
  }

  // ─── Computed properties ───────────────────────────────────────────────────

  int get _currentSection => _steps[_currentStep].section;

  // ─── Navigation ────────────────────────────────────────────────────────────

  // Step indices for the conditional dismissal follow-up (Screen 3).
  static const _kFeltDismissedStep = 4;
  static const _kSupportNeedsStep = 7;

  void _goNext() {
    FocusScope.of(context).unfocus();
    int nextStep = _currentStep + 1;

    // Skip dismissal-detail steps (5 & 6) when the user was not dismissed.
    if (_currentStep == _kFeltDismissedStep &&
        _answers[_kFeltDismissedStep] != 'Yes') {
      nextStep = _kSupportNeedsStep;
    }

    if (nextStep <= _steps.length - 1) {
      setState(() => _currentStep = nextStep);
      _pageController.animateToPage(
        nextStep,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
  } else {
      // All questions answered — persist answers then show activation screen.
      _saveProfile();
      setState(() => _step = _OnboardingStep.activation);
    }
  }

  void _goBack() {
    int prevStep = _currentStep - 1;

    // Skip back over dismissal-detail steps when not applicable.
    if (_currentStep == _kSupportNeedsStep &&
        _answers[_kFeltDismissedStep] != 'Yes') {
      prevStep = _kFeltDismissedStep;
    }

    if (prevStep >= 0) {
      setState(() => _currentStep = prevStep);
      _pageController.animateToPage(
        prevStep,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    }
    // At step 0: sign-up is complete — nothing further to go back to.
  }

  // ─── Answer logic ──────────────────────────────────────────────────────────

  bool _canProceed() {
    final step = _steps[_currentStep];
    if (step.type == _StepType.textInput) {
      final text = _textControllers[_currentStep]?.text.trim() ?? '';
      if (text.isEmpty) return step.optional;
      return _getValidationError(_currentStep) == null;
    }
    if (step.optional) return true;
    final answer = _answers[_currentStep];
    if (answer == null) return false;
    if (answer is List) return answer.isNotEmpty;
    return true;
  }

  bool _isSelected(int stepIndex, String option) {
    final answer = _answers[stepIndex];
    if (answer == null) return false;
    if (answer is List) return (answer as List<String>).contains(option);
    return answer == option;
  }

  void _selectOption(int stepIndex, String option, _StepType type) {
    setState(() {
      if (type == _StepType.singleSelect) {
        _answers[stepIndex] = option;
      } else {
        final step = _steps[stepIndex];
        final current =
            List<String>.from((_answers[stepIndex] as List?) ?? []);
        if (current.contains(option)) {
          current.remove(option);
        } else {
          if (step.exclusiveOptions.contains(option)) {
            current
              ..clear()
              ..add(option);
          } else {
            for (final excl in step.exclusiveOptions) {
              current.remove(excl);
            }
            if (step.maxSelections == null ||
                current.length < step.maxSelections!) {
              current.add(option);
            }
          }
        }
        _answers[stepIndex] = current;
      }
    });
  }

  TextEditingController _getTextController(int stepIndex) {
    return _textControllers.putIfAbsent(stepIndex, () {
      final c = TextEditingController();
      c.addListener(() {
        if (mounted) setState(() {});
      });
      return c;
    });
  }

  // ─── Validation ────────────────────────────────────────────────────────────

  String? _getValidationError(int stepIndex) {
    final step = _steps[stepIndex];
    if (step.validatorType == _ValidatorType.none) return null;
    final text = _textControllers[stepIndex]?.text.trim() ?? '';
    if (text.isEmpty) return null;
    switch (step.validatorType) {
      case _ValidatorType.zipCode:
        return _validateZipCode(text);
      case _ValidatorType.none:
        return null;
    }
  }

  /// Accepts only a 5-digit US ZIP code.
  /// NOTE: the backend truncates to the first 3 digits before persisting.
  String? _validateZipCode(String text) {
    if (!RegExp(r'^\d{5}$').hasMatch(text)) {
      return 'Please enter a valid 5-digit ZIP code.';
    }
    return null;
  }

  // ─── Build

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: switch (_step) {
            _OnboardingStep.intro => _IntroPage(
                key: const ValueKey('intro'),
                onStart: () => setState(() => _step = _OnboardingStep.signUp),
              ),
            _OnboardingStep.signUp => _SignUpPage(
                key: const ValueKey('signup'),
                onSignUpComplete: () =>
                    setState(() => _step = _OnboardingStep.questions),
                onBack: () => setState(() => _step = _OnboardingStep.intro),
              ),
            _OnboardingStep.questions => _QuestionsPage(
                key: const ValueKey('questions'),
                steps: _steps,
                currentStep: _currentStep,
                currentSection: _currentSection,
                sectionTitles: _sectionTitles,
                pageController: _pageController,
                answers: _answers,
                canProceed: _canProceed(),
                isLast: _currentStep == _steps.length - 1,
                isSelected: _isSelected,
                onSelect: _selectOption,
                onNext: _goNext,
                onBack: _goBack,
                getTextController: _getTextController,
                getValidationError: _getValidationError,
              ),
            _OnboardingStep.activation => _ActivationPage(
                key: const ValueKey('activation'),
                onComplete: widget.onComplete,
              ),
          },
        ),
      ),
    );
  }
}

// ─── Activation Page ──────────────────────────────────────────────────────────

class _ActivationPage extends StatelessWidget {
  const _ActivationPage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;

    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          // Wordmark
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 10.5 * vw,
                color: const Color(0xFFC9A96E),
                fontWeight: FontWeight.w300,
                letterSpacing: 5.0,
              ),
              children: const [TextSpan(text: 'WHELBEING')],
            ),
          ),

          SizedBox(height: 7 * vh),

          // Heading
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8 * vw),
            child: Text(
              "You're all set.",
              style: TextStyle(
                fontSize: 10.5 * vw,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFE8DCC8),
                height: 1.08,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 2.5 * vh),

          // Subtext
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10 * vw),
            child: Text(
              'Whenever you need support\u2014before, during, or after '
              'a visit\u2014we\u2019ve got you.',
              style: TextStyle(
                fontSize: 4.0 * vw,
                color: const Color(0xFF5A4A3A),
                height: 1.65,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const Spacer(flex: 2),

          // CTA button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8 * vw),
            child: GestureDetector(
              onTap: onComplete,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 2.1 * vh),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC9A96E), Color(0xFF8B6914)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC9A96E).withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'GET SUPPORT NOW',
                        style: TextStyle(
                          fontSize: 3.0 * vw,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0D0D0D),
                          letterSpacing: 2.2,
                        ),
                      ),
                      SizedBox(width: 2.5 * vw),
                      Icon(
                        Icons.arrow_forward,
                        color: const Color(0xFF0D0D0D),
                        size: 3.8 * vw,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const Spacer(flex: 1),
        ],
      ),
    );
  }
}

// ─── Intro Page ─────────────────────────────────────────────────────────────────

class _IntroPage extends StatelessWidget {
  const _IntroPage({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;

    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // BWHEL wordmark
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 11.5 * vw,
                color: const Color(0xFFC9A96E),
                fontWeight: FontWeight.w300,
                letterSpacing: 5.0,
              ),
              children: const [
                TextSpan(text: 'WHELBEING'),
              ],
            ),
          ),
          SizedBox(height: 1.8 * vh),

          // Tagline
          Text(
            'Infrastructure disguised as lifestyle.',
            style: TextStyle(
              fontSize: 3.4 * vw,
              color: const Color(0xFF524840),
              fontStyle: FontStyle.italic,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.5 * vh),

          // Thin divider
          Container(
            width: 18 * vw,
            height: 0.8,
            color: const Color(0xFF2E2520),
          ),
          SizedBox(height: 3 * vh),

          // Descriptor
          Text(
            'HEALTH NAVIGATION',
            style: TextStyle(
              fontSize: 2.6 * vw,
              color: const Color(0xFF3E3530),
              letterSpacing: 3.5,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.8 * vh),
          Text(
            'FOR BLACK WOMEN',
            style: TextStyle(
              fontSize: 2.6 * vw,
              color: const Color(0xFF3E3530),
              letterSpacing: 3.5,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(flex: 2),

          // GET STARTED button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8 * vw),
            child: GestureDetector(
              onTap: onStart,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 2 * vh),
                decoration: BoxDecoration(
                  color: const Color(0xFF181310),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF3D2E14), width: 0.8),
                ),
                child: Center(
                  child: Text(
                    'GET STARTED',
                    style: TextStyle(
                      fontSize: 3.0 * vw,
                      color: const Color(0xFFE8DCC8),
                      letterSpacing: 3.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 2 * vh),

          // Sign-in link
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SignInScreen()),
            ),
            child: Text(
              'Already a member? Sign in',
              style: TextStyle(
                fontSize: 3.0 * vw,
                color: const Color(0xFF6A5A4A),
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF3A3030),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const Spacer(flex: 1),
        ],
      ),
    );
  }
}

// ─── Sign-up Page ─────────────────────────────────────────────────────────────────

class _SignUpPage extends ConsumerStatefulWidget {
  const _SignUpPage({
    super.key,
    required this.onSignUpComplete,
    required this.onBack,
  });

  final VoidCallback onSignUpComplete;
  final VoidCallback onBack;

  @override
  ConsumerState<_SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<_SignUpPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _localError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final firstName = _firstNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (firstName.isEmpty || email.isEmpty || password.isEmpty) return;

    // Password strength
    final passwordError = Validators.password(password);
    if (passwordError != null) {
      setState(() => _localError = passwordError);
      return;
    }

    setState(() => _localError = null);
    ref.read(signInProvider.notifier).signUpWithEmail(
      email,
      password,
      firstName: firstName,
      lastName: _lastNameController.text.trim().isEmpty
          ? null
          : _lastNameController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Advance to health-profile questions as soon as any sign-up method succeeds.
    ref.listen<bool>(isAuthenticatedProvider, (_, isAuth) {
      if (isAuth && context.mounted) widget.onSignUpComplete();
    });

    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    final state = ref.watch(signInProvider);
    final notifier = ref.read(signInProvider.notifier);

    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Back button ───────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(5 * vw, 2 * vh, 0, 0),
            child: GestureDetector(
              onTap: widget.onBack,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: const Color(0xFF6A5A4A),
                size: 5.5 * vw,
              ),
            ),
          ),
          // ── Scrollable content ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(6 * vw, 3 * vh, 6 * vw, 4 * vh),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
            // ── Brand mark ──────────────────────────────────────────────────
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 9 * vw,
                  color: const Color(0xFFC9A96E),
                  fontWeight: FontWeight.w300,
                  letterSpacing: 4.0,
                ),
                children: const [
                  TextSpan(text: 'WHELBEING'),
                ],
              ),
            ),
            SizedBox(height: 0.6 * vh),
            Text(
              'Infrastructure disguised as lifestyle.',
              style: TextStyle(
                fontSize: 3.0 * vw,
                color: const Color(0xFF4A4040),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4 * vh),

            // ── Heading ──────────────────────────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create your\naccount.',
                    style: TextStyle(
                      fontSize: 9.5 * vw,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE8DCC8),
                      height: 1.08,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 1.5 * vh),
                  Text(
                    'Join BWhel and take control of your health.',
                    style: TextStyle(
                      fontSize: 3.5 * vw,
                      color: const Color(0xFF5A4A3A),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4 * vh),

    // ── Error banner ────────────────────────────────────────────────
            if (_localError != null || state.error != null) ...[  
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.5 * vw),
                margin: EdgeInsets.only(bottom: 2.5 * vh),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1010),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF5A2020)),
                ),
                child: Text(
                  _localError ?? state.error!,
                  style: TextStyle(
                    fontSize: 3.0 * vw,
                    color: const Color(0xFFE08080),
                    height: 1.5,
                  ),
                ),
              ),
            ],

            // ── Form fields ─────────────────────────────────────────────
            _OBTextField(
              controller: _firstNameController,
              hint: 'First name',
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              vw: vw,
              vh: vh,
            ),
            SizedBox(height: 1.5 * vh),
            _OBTextField(
              controller: _lastNameController,
              hint: 'Last name (optional)',
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              vw: vw,
              vh: vh,
            ),
            SizedBox(height: 1.5 * vh),
            _OBTextField(
              controller: _emailController,
              hint: 'Email address',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              vw: vw,
              vh: vh,
            ),
            SizedBox(height: 1.5 * vh),
            _OBTextField(
              controller: _passwordController,
              hint: 'Password',
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              vw: vw,
              vh: vh,
              suffix: GestureDetector(
                onTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3 * vw),
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF5A4A3A),
                    size: 5 * vw,
                  ),
                ),
              ),
            ),
            SizedBox(height: 3 * vh),

            // ── Create Account button ───────────────────────────────────────
            GestureDetector(
              onTap: state.isLoading ? null : _submit,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 2.1 * vh),
                decoration: BoxDecoration(
                  gradient: state.isLoading
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFFC9A96E), Color(0xFF8B6914)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  color: state.isLoading ? const Color(0xFF141414) : null,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.isLoading
                        ? const Color(0xFF222220)
                        : Colors.transparent,
                  ),
                  boxShadow: state.isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFFC9A96E).withValues(alpha: 0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 3),
                          )
                        ],
                ),
                child: Center(
                  child: state.loadingEmail
                      ? SizedBox(
                          width: 5.5 * vw,
                          height: 5.5 * vw,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: state.isLoading
                                ? const Color(0xFF4A4A4A)
                                : const Color(0xFF0D0D0D),
                          ),
                        )
                      : Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 3.4 * vw,
                            fontWeight: FontWeight.w700,
                            color: state.isLoading
                                ? const Color(0xFF3A3A3A)
                                : const Color(0xFF0D0D0D),
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(height: 4 * vh),

            // ── Divider ────────────────────────────────────────────────────
            // Row(
            //   children: [
            //     const Expanded(
            //         child: Divider(color: Color(0xFF1E1E1A), height: 1)),
            //     Padding(
            //       padding: EdgeInsets.symmetric(horizontal: 3 * vw),
            //       child: Text(
            //         'or',
            //         style: TextStyle(
            //             fontSize: 3.0 * vw,
            //             color: const Color(0xFF3A3028)),
            //       ),
            //     ),
            //     const Expanded(
            //         child: Divider(color: Color(0xFF1E1E1A), height: 1)),
            //   ],
            // ),
            // SizedBox(height: 4 * vh),

            // // ── Google ────────────────────────────────────────────────────
            // _OBOAuthButton(
            //   label: 'Sign up with Google',
            //   icon: Text(
            //     'G',
            //     style: TextStyle(
            //       fontSize: 5 * vw,
            //       fontWeight: FontWeight.w700,
            //       color: const Color(0xFF4285F4),
            //     ),
            //   ),
            //   loading: state.loadingGoogle,
            //   disabled: state.isLoading,
            //   onTap: notifier.signInWithGoogle,
            //   vh: vh,
            //   vw: vw,
            // ),

            // // ── Apple (iOS only) ─────────────────────────────────────────────
            // if (Platform.isIOS) ...[
            //   SizedBox(height: 1.5 * vh),
            //   _OBOAuthButton(
            //     label: 'Sign up with Apple',
            //     icon: Text(
            //       '\uF8FF',
            //       style: TextStyle(
            //           fontSize: 5.5 * vw, color: const Color(0xFFE8DCC8)),
            //     ),
            //     loading: state.loadingApple,
            //     disabled: state.isLoading,
            //     onTap: notifier.signInWithApple,
            //     vh: vh,
            //     vw: vw,
            //   ),
            // ],
            // SizedBox(height: 4 * vh),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Onboarding form helpers ───────────────────────────────────────────────────────

class _OBTextField extends StatelessWidget {
  const _OBTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
    this.maxLines = 1,
    this.minLines,
    required this.vw,
    required this.vh,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final int maxLines;
  final int? minLines;
  final double vw;
  final double vh;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      maxLines: maxLines,
      minLines: minLines,
      style: TextStyle(fontSize: 4.0 * vw, color: const Color(0xFFE8DCC8)),
      cursorColor: const Color(0xFFC9A96E),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(fontSize: 4.0 * vw, color: const Color(0xFF3A2E24)),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF111111),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 4.5 * vw, vertical: 2 * vh),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A2520)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFFC9A96E).withValues(alpha: 0.55),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _OBOAuthButton extends StatelessWidget {
  const _OBOAuthButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.disabled,
    required this.onTap,
    required this.vh,
    required this.vw,
  });

  final String label;
  final Widget icon;
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;
  final double vh;
  final double vw;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 2.1 * vh, horizontal: 5 * vw),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                disabled ? const Color(0xFF1E1E1A) : const Color(0xFF2A2520),
          ),
        ),
        child: loading
            ? Center(
                child: SizedBox(
                  width: 5.5 * vw,
                  height: 5.5 * vw,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFC9A96E),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  SizedBox(width: 3.5 * vw),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 3.8 * vw,
                      color: disabled
                          ? const Color(0xFF5A5A5A)
                          : const Color(0xFFE8DCC8),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Questions Page ───────────────────────────────────────────────────────────

class _QuestionsPage extends StatelessWidget {
  final List<_StepConfig> steps;
  final int currentStep;
  final int currentSection;
  final List<String> sectionTitles;
  final PageController pageController;
  final Map<int, dynamic> answers;
  final bool canProceed;
  final bool isLast;
  final bool Function(int, String) isSelected;
  final void Function(int, String, _StepType) onSelect;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final TextEditingController Function(int) getTextController;
  final String? Function(int) getValidationError;

  const _QuestionsPage({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.currentSection,
    required this.sectionTitles,
    required this.pageController,
    required this.answers,
    required this.canProceed,
    required this.isLast,
    required this.isSelected,
    required this.onSelect,
    required this.onNext,
    required this.onBack,
    required this.getTextController,
    required this.getValidationError,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;

    return Column(
      children: [
        _buildProgressHeader(vh, vw),
        Expanded(
          child: PageView.builder(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            itemBuilder: (_, index) => _buildStepContent(index, vh, vw),
          ),
        ),
        _buildBottomNav(vh, vw),
      ],
    );
  }

  // ── Progress header ─────────────────────────────────────────────────────────

  Widget _buildProgressHeader(double vh, double vw) {
    // Segment 0 = Welcome screen (already passed). Segments 1–6 = question
    // screens 2–7. The active segment index = currentSection + 1.
    final progressIndex = currentSection + 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(6 * vw, 3 * vh, 6 * vw, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 7-segment bar (1 welcome + 6 question screens)
          Row(
            children: List.generate(7, (i) {
              final done = i < progressIndex;
              final active = i == progressIndex;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 6 ? 1.4 * vw : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeInOut,
                    height: 0.45 * vh,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: done
                          ? const Color(0xFFC9A96E)
                          : active
                              ? const Color(0xFFE8DCC8)
                              : const Color(0xFF1E1E1A),
                    ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 1.8 * vh),
          // Screen label
          Row(
            children: [
              Text(
                'SCREEN ${currentSection + 2} OF 7',
                style: TextStyle(
                  fontSize: 2.7 * vw,
                  color: const Color(0xFF8A7A6A),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
              Text(
                '  ·  ${sectionTitles[currentSection].toUpperCase()}',
                style: TextStyle(
                  fontSize: 2.7 * vw,
                  color: const Color(0xFF4A3E32),
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Inline text field helper ────────────────────────────────────────────────

  bool _showInlineTextField(int stepIndex) {
    final step = steps[stepIndex];
    if (step.textFieldOption == null) return false;
    final answer = answers[stepIndex];
    if (step.type == _StepType.singleSelect) {
      return answer == step.textFieldOption;
    } else if (step.type == _StepType.multiSelect) {
      return (answer as List<String>?)?.contains(step.textFieldOption) == true;
    }
    return false;
  }

  // ── Step content ────────────────────────────────────────────────────────────

  Widget _buildStepContent(int index, double vh, double vw) {
    final step = steps[index];
    // Show a badge only for constrained multiselects (all steps are optional).
    final hasTopBadge = step.type == _StepType.multiSelect;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(6 * vw, 3.5 * vh, 6 * vw, 2 * vh),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen-level context header (italic gold)
          if (step.heroText != null) ...[
            Text(
              step.heroText!,
              style: TextStyle(
                fontSize: 5.8 * vw,
                fontStyle: FontStyle.italic,
                color: const Color(0xFFC9A96E),
                fontWeight: FontWeight.w300,
                height: 1.3,
                letterSpacing: -0.2,
              ),
            ),
            if (step.heroSubtext != null) ...[
              SizedBox(height: 1.5 * vh),
              Text(
                step.heroSubtext!,
                style: TextStyle(
                  fontSize: 3.3 * vw,
                  color: const Color(0xFF5A4A3A),
                  height: 1.7,
                ),
              ),
            ],
            SizedBox(height: 3 * vh),
            Container(height: 0.6, color: const Color(0xFF1A1A18)),
            SizedBox(height: 3 * vh),
          ],

          // Multiselect badge
          if (hasTopBadge) ...[
            _Badge(
              label: step.maxSelections != null
                  ? 'Select up to ${step.maxSelections}'
                  : 'Select all that apply',
              vw: vw,
              vh: vh,
            ),
            SizedBox(height: 2.2 * vh),
          ],

          // Question
          Text(
            step.question,
            style: TextStyle(
              fontSize: 7.4 * vw,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE8DCC8),
              height: 1.18,
              letterSpacing: -0.5,
            ),
          ),
          if (step.subtitle != null) ...[
            SizedBox(height: 1.6 * vh),
            Text(
              step.subtitle!,
              style: TextStyle(
                fontSize: 3.3 * vw,
                color: const Color(0xFF5A4A3A),
                height: 1.55,
              ),
            ),
          ],
          SizedBox(height: 4 * vh),

          // Content: standalone text field OR options list
          if (step.type == _StepType.textInput) ...[
            _OBTextField(
              controller: getTextController(index),
              hint: step.textHint ?? '',
              keyboardType: step.keyboardType,
              maxLines: step.multilineText ? 4 : 1,
              minLines: step.multilineText ? 3 : null,
              vw: vw,
              vh: vh,
            ),
            _buildValidationError(getValidationError(index), vh, vw),
          ] else ...[
            ...step.options.asMap().entries.map(
              (entry) => _OptionTile(
                label: entry.value,
                description: step.optionDescriptions != null &&
                        entry.key < step.optionDescriptions!.length
                    ? step.optionDescriptions![entry.key]
                    : null,
                selected: isSelected(index, entry.value),
                type: step.type,
                vh: vh,
                vw: vw,
                onTap: () => onSelect(index, entry.value, step.type),
              ),
            ),
            // Inline text field revealed by trigger option
            if (_showInlineTextField(index)) ...[
              SizedBox(height: 0.5 * vh),
              _OBTextField(
                controller: getTextController(index),
                hint: step.textHint ?? '',
                vw: vw,
                vh: vh,
              ),
              SizedBox(height: 1.5 * vh),
            ],
          ],
          SizedBox(height: 2 * vh),
        ],
      ),
    );
  }

  // ── Validation error ──────────────────────────────────────────────────────────

  Widget _buildValidationError(String? error, double vh, double vw) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: 1.5 * vh),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 3.8 * vw,
            color: const Color(0xFFE08080),
          ),
          SizedBox(width: 1.5 * vw),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                fontSize: 3.2 * vw,
                color: const Color(0xFFE08080),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav(double vh, double vw) {
    return Container(
      padding: EdgeInsets.fromLTRB(6 * vw, 2 * vh, 6 * vw, 3.5 * vh),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF181815), width: 1)),
      ),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 4.8 * vw, vertical: 2 * vh),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2520)),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: const Color(0xFF6A5A4A),
                size: 4.5 * vw,
              ),
            ),
          ),
          SizedBox(width: 3 * vw),
          // Continue / Enter
          Expanded(
            child: GestureDetector(
            onTap: canProceed ? onNext : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(vertical: 2.1 * vh),
                decoration: isLast
                    ? BoxDecoration(
                        gradient: canProceed
                            ? const LinearGradient(
                                colors: [Color(0xFFC9A96E), Color(0xFF8B6914)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : null,
                        color: canProceed ? null : const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: canProceed
                              ? Colors.transparent
                              : const Color(0xFF222220),
                        ),
                        boxShadow: canProceed
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFC9A96E)
                                      .withValues(alpha: 0.25),
                                  blurRadius: 18,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : [],
                      )
                    : BoxDecoration(
                        color: canProceed
                            ? const Color(0xFF181410)
                            : const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: canProceed
                              ? const Color(0xFF3D2E14)
                              : const Color(0xFF1E1E1A),
                        ),
                      ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLast ? 'FINISH' : 'CONTINUE',
                        style: TextStyle(
                          fontSize: 3.4 * vw,
                          fontWeight: FontWeight.w700,
                          color: canProceed
                              ? (isLast
                                  ? const Color(0xFF0D0D0D)
                                  : const Color(0xFFE8DCC8))
                              : const Color(0xFF2E2E2A),
                          letterSpacing: 2.2,
                        ),
                      ),
                      if (canProceed) ...[  
                        SizedBox(width: 2.5 * vw),
                        Icon(
                          Icons.arrow_forward,
                          color: isLast
                              ? const Color(0xFF0D0D0D)
                              : const Color(0xFFC9A96E),
                          size: 4 * vw,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable sub-widgets ─────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final bool isGold;
  final double vw;
  final double vh;

  const _Badge({
    required this.label,
    this.isGold = false, // ignore: unused_element_parameter
    required this.vw,
    required this.vh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 2.8 * vw, vertical: 0.45 * vh),
      decoration: BoxDecoration(
        color: isGold
            ? const Color(0xFF3D2E14).withValues(alpha: 0.35)
            : const Color(0xFF252218).withValues(alpha: 0.6),
        border: Border.all(
          color: isGold
              ? const Color(0xFF6B5220).withValues(alpha: 0.65)
              : const Color(0xFF3A3020).withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 2.8 * vw,
          color:
              isGold ? const Color(0xFF9A7830) : const Color(0xFF7A6A50),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final String? description;
  final bool selected;
  final _StepType type;
  final double vw;
  final double vh;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    this.description,
    required this.selected,
    required this.type,
    required this.vw,
    required this.vh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDesc = description != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 1.8 * vh),
        padding: EdgeInsets.symmetric(
          horizontal: 4.5 * vw,
          vertical: hasDesc ? 2.4 * vh : 2.0 * vh,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1208) : const Color(0xFF0F0F0E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFFC9A96E)
                : const Color(0xFF222220),
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFC9A96E).withValues(alpha: 0.09),
                    blurRadius: 14,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Indicator — LEFT side
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 5 * vw,
              height: 5 * vw,
              decoration: BoxDecoration(
                shape: type == _StepType.singleSelect
                    ? BoxShape.circle
                    : BoxShape.rectangle,
                borderRadius: type == _StepType.multiSelect
                    ? BorderRadius.circular(4)
                    : null,
                color: selected
                    ? const Color(0xFFC9A96E)
                    : Colors.transparent,
                border: selected
                    ? null
                    : Border.all(
                        color: const Color(0xFF3A3530), width: 1.5),
              ),
              child: selected
                  ? Icon(Icons.check,
                      color: const Color(0xFF0D0D0D), size: 3.0 * vw)
                  : null,
            ),
            SizedBox(width: 4 * vw),
            // Label + optional description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 3.9 * vw,
                      color: selected
                          ? const Color(0xFFE8DCC8)
                          : const Color(0xFF8A7A6A),
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (hasDesc) ...[
                    SizedBox(height: 0.55 * vh),
                    Text(
                      description!,
                      style: TextStyle(
                        fontSize: 3.0 * vw,
                        color: selected
                            ? const Color(0xFF9A8870)
                            : const Color(0xFF4A3E30),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
