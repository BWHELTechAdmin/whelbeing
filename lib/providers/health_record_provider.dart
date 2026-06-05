import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_record_model.dart';
import '../repositories/health_record_repository.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// Notifier — mutable list that supports optimistic inserts
// ---------------------------------------------------------------------------

class HealthRecordsNotifier extends AsyncNotifier<List<HealthRecordModel>> {
  @override
  Future<List<HealthRecordModel>> build() async {
    ref.watch(currentSessionProvider); // Rebuild on auth change.
    return ref.read(healthRecordRepositoryProvider).fetchAll();
  }

  /// Inserts a new record in Supabase and prepends it to the local list so
  /// the UI updates immediately without a full refetch.
  Future<void> addRecord({
    required HealthRecordType type,
    required DateTime recordDate,
    required String title,
    String? notes,
  }) async {
    final repo = ref.read(healthRecordRepositoryProvider);
    final record = await repo.insert(
      type: type,
      recordDate: recordDate,
      title: title,
      notes: notes,
    );
    state = AsyncData([record, ...state.valueOrNull ?? []]);
  }
}

/// The signed-in user's health records, newest first.
final healthRecordsProvider =
    AsyncNotifierProvider<HealthRecordsNotifier, List<HealthRecordModel>>(
  HealthRecordsNotifier.new,
);

// ---------------------------------------------------------------------------
// Count provider — used in the Profile screen stats card
// ---------------------------------------------------------------------------

/// Total number of health records for the current user.
final healthRecordCountProvider = FutureProvider<int>((ref) async {
  ref.watch(currentSessionProvider);
  return ref.read(healthRecordRepositoryProvider).countAll();
});

// ---------------------------------------------------------------------------
// Streak — consecutive calendar days with at least one health record
// ---------------------------------------------------------------------------

/// Number of consecutive calendar days (ending today or yesterday) on which
/// the user opened the app. Computed server-side via `get_streak()` RPC.
final streakProvider = FutureProvider<int>((ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return 0;
  final result = await ref.read(supabaseClientProvider).rpc('get_streak');
  return (result as num?)?.toInt() ?? 0;
});
