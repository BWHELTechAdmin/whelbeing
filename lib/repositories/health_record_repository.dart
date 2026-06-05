import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/health_record_model.dart';
import '../providers/auth_provider.dart';

/// Handles CRUD operations on `public.health_records`.
class HealthRecordRepository {
  const HealthRecordRepository(this._client);

  final SupabaseClient _client;

  /// Returns all records for the current user, newest first.
  Future<List<HealthRecordModel>> fetchAll() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('health_records')
        .select()
        .eq('user_id', userId)
        .order('record_date', ascending: false);

    return (data as List)
        .map((e) => HealthRecordModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Inserts a new record and returns the persisted row.
  Future<HealthRecordModel> insert({
    required HealthRecordType type,
    required DateTime recordDate,
    required String title,
    String? notes,
    HealthRecordStatus status = HealthRecordStatus.none,
    String? aiSuggestion,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('No authenticated user');

    final payload = <String, dynamic>{
      'user_id': userId,
      'type': type.toDb,
      'record_date':
          '${recordDate.year}-${recordDate.month.toString().padLeft(2, '0')}-${recordDate.day.toString().padLeft(2, '0')}',
      'title': title,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'status': status.toDb,
      if (aiSuggestion != null) 'ai_suggestion': aiSuggestion,
    };

    final result = await _client
        .from('health_records')
        .insert(payload)
        .select()
        .single();

    return HealthRecordModel.fromJson(result);
  }

  /// Returns the total number of records for the current user.
  Future<int> countAll() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final data = await _client
        .from('health_records')
        .select('id')
        .eq('user_id', userId);

    return (data as List).length;
  }
}

final healthRecordRepositoryProvider = Provider<HealthRecordRepository>((ref) {
  return HealthRecordRepository(ref.watch(supabaseClientProvider));
});
