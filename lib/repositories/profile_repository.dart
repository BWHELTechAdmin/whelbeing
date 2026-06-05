import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';

/// Handles reads/writes to `public.onboarding_profiles`.
class ProfileRepository {
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  /// Upserts onboarding answers into `public.onboarding_profiles`.
  ///
  /// All parameters are optional — only non-null values are included in the
  /// upsert, so partial saves are always safe. String values from the UI are
  /// mapped to the controlled enum values the DB expects.
  Future<void> saveOnboardingProfile({
    List<String>? racialIdentity,   // Step 0
    String? ageRange,         // Step 1
    String? zipCode,          // Step 2
    String? insuranceType,    // Step 3
    String? feltDismissed,    // Step 4
    List<String>? dismissalExperiences, // Step 5
    String? dismissalCareType,          // Step 6
    List<String>? supportNeeds,         // Step 7
    String? supportTiming,              // Step 8
    String? realtimeInterest,           // Step 9
    List<String>? healthAreas,          // Step 10
    String? dataConsent,                // Step 11
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final data = <String, dynamic>{'id': userId};

    // Step 0 — racial identities (multi-select, stored as text[])
    final racialIds = racialIdentity
        ?.map(_mapRacialIdentity)
        .whereType<String>()
        .toList();
    if (racialIds != null && racialIds.isNotEmpty) {
      data['racial_identity'] = racialIds;
    }

    // Step 1 — age range
    final age = _mapAgeRange(ageRange);
    if (age != null) data['age_range'] = age;

    // Step 2 — ZIP → first 3 digits only
    if (zipCode != null && zipCode.length >= 3) {
      data['zip_prefix'] = zipCode.substring(0, 3);
    }

    // Step 3 — insurance type
    final ins = _mapInsurance(insuranceType);
    if (ins != null) data['insurance_type'] = ins;

    // Step 4 — dismissal yes/no
    final dismissed = _mapFeltDismissed(feltDismissed);
    if (dismissed != null) data['felt_dismissed'] = dismissed;

    // Step 5 — dismissal detail checkboxes
    final dismissalExp = dismissalExperiences
        ?.map(_mapDismissalExperience)
        .whereType<String>()
        .toList();
    if (dismissalExp != null && dismissalExp.isNotEmpty) {
      data['dismissal_experiences'] = dismissalExp;
    }

    // Step 6 — care type
    final careType = _mapCareType(dismissalCareType);
    if (careType != null) data['dismissal_care_type'] = careType;

    // Step 7 — support needs (free labels, stored as-is)
    if (supportNeeds != null && supportNeeds.isNotEmpty) {
      data['support_needs'] = supportNeeds;
    }

    // Step 8 — support timing
    final timing = _mapSupportTiming(supportTiming);
    if (timing != null) data['support_timing'] = timing;

    // Step 9 — real-time interest
    final realtime = _mapRealtimeInterest(realtimeInterest);
    if (realtime != null) data['realtime_interest'] = realtime;

    // Step 10 — health areas
    final areas = healthAreas
        ?.map(_mapHealthArea)
        .whereType<String>()
        .toList();
    if (areas != null && areas.isNotEmpty) data['health_areas'] = areas;

    // Step 11 — data consent
    if (dataConsent == 'Yes') data['data_consent'] = true;
    if (dataConsent == 'No') data['data_consent'] = false;

    if (data.length <= 1) return; // Nothing to save beyond the ID.

    await _client.from('onboarding_profiles').upsert(data);
  }

  // ── Value mappers ─────────────────────────────────────────────────────────

  static String? _mapRacialIdentity(String v) => switch (v) {
        'Black / African American' => 'black_african_american',
        'Afro-Caribbean'           => 'afro_caribbean',
        'African immigrant'        => 'african_immigrant',
        'Multiracial'              => 'multiracial',
        'Prefer not to say'        => 'prefer_not_to_say',
        _                          => null,
      };

  static String? _mapAgeRange(String? v) => switch (v) {
        '18\u201324' => '18_24',
        '25\u201334' => '25_34',
        '35\u201344' => '35_44',
        '45\u201354' => '45_54',
        '55+'        => '55_plus',
        _            => null,
      };

  static String? _mapInsurance(String? v) => switch (v) {
        'Medicaid'         => 'medicaid',
        'Medicare'         => 'medicare',
        'Private insurance'=> 'private',
        'Uninsured'        => 'uninsured',
        'Not sure'         => 'not_sure',
        _                  => null,
      };

  static String? _mapFeltDismissed(String? v) => switch (v) {
        'Yes'         => 'yes',
        'No'          => 'no',
        "I'm not sure" => 'not_sure',
        _             => null,
      };

  static String? _mapDismissalExperience(String v) => switch (v) {
        'My symptoms were brushed off'                        => 'symptoms_brushed_off',
        "I was told \"it's nothing\" but it didn't feel like nothing" => 'told_its_nothing',
        'I was denied a test or treatment'                    => 'denied_test',
        'The visit felt rushed'                               => 'visit_rushed',
        "I didn't get clear answers"                          => 'no_clear_answers',
        'I felt judged or stereotyped'                        => 'felt_judged',
        'Other'                                               => 'other',
        _                                                     => null,
      };

  static String? _mapCareType(String? v) => switch (v) {
        'Primary care'  => 'primary_care',
        'OB/GYN'        => 'ob_gyn',
        'Emergency room'=> 'emergency_room',
        'Mental health' => 'mental_health',
        'Specialist'    => 'specialist',
        _               => null,
      };

  static String? _mapSupportTiming(String? v) => switch (v) {
        'Before appointments'           => 'before',
        'During appointments'           => 'during',
        'After appointments'            => 'after',
        'Honestly\u2026all of it'       => 'all_of_it',
        _                               => null,
      };

  static String? _mapRealtimeInterest(String? v) => switch (v) {
        'Yes, absolutely' => 'yes_absolutely',
        "I'd try it"      => 'id_try_it',
        'Not sure yet'    => 'not_sure',
        _                 => null,
      };

  static String? _mapHealthArea(String v) => switch (v) {
        'Reproductive health education'                  => 'reproductive_health',
        'Understanding ongoing or unexplained symptoms'  => 'unexplained_symptoms',
        'Mental wellness support'                        => 'mental_wellness',
        'Heart health awareness'                         => 'heart_health',
        'Just trying to stay on top of my health'        => 'staying_on_top',
        'Prefer not to say'                              => 'prefer_not_to_say',
        _                                                => null,
      };

  // ── Fetch / update health areas ───────────────────────────────────────────

  /// Returns the user's health focus areas as display-friendly strings.
  /// DB enum values are reverse-mapped; unrecognised (free-text) values are
  /// returned as-is. 'prefer_not_to_say' entries are filtered out.
  Future<List<String>> fetchHealthAreas() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('onboarding_profiles')
        .select('health_areas')
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return [];
    final raw = (data['health_areas'] as List?)?.cast<String>() ?? [];
    return raw
        .map(_reverseMapHealthArea)
        .where((s) => s != null)
        .cast<String>()
        .toList();
  }

  /// Appends [area] to the user's `health_areas` list in the DB.
  Future<void> addHealthArea(String area) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final data = await _client
        .from('onboarding_profiles')
        .select('health_areas')
        .eq('id', userId)
        .maybeSingle();

    final existing = (data?['health_areas'] as List?)?.cast<String>() ?? [];
    await _client.from('onboarding_profiles').upsert({
      'id': userId,
      'health_areas': [...existing, area],
    });
  }

  static String? _reverseMapHealthArea(String v) => switch (v) {
        'reproductive_health'  => 'Reproductive health',
        'unexplained_symptoms' => 'Unexplained symptoms',
        'mental_wellness'      => 'Mental wellness',
        'heart_health'         => 'Heart health',
        'staying_on_top'       => 'Staying on top of health',
        'prefer_not_to_say'    => null,
        _                      => v,
      };
}

// ─── Providers ─────────────────────────────────────────────────────

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

/// The user's health focus areas, fetched from `onboarding_profiles`.
/// Rebuilds whenever the auth session changes.
final healthAreasProvider = FutureProvider<List<String>>((ref) async {
  ref.watch(currentSessionProvider);
  return ref.read(profileRepositoryProvider).fetchHealthAreas();
});
