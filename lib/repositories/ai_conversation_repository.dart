import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_conversation.dart';
import '../services/ai_service.dart';

class AiConversationRepository {
  static final _client = Supabase.instance.client;
  static const _table = 'ai_conversations';
  static const pageSize = 5;

  /// Returns a page of conversations ordered by most recent activity.
  static Future<List<AiConversation>> fetchPage(int page) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    final data = await _client
        .from(_table)
        .select()
        .order('last_message_at', ascending: false)
        .range(from, to);

    return (data as List<dynamic>)
        .map((e) => AiConversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a new conversation record after the first complete turn.
  /// [messages] should contain only real exchange messages (no greeting seed).
  static Future<AiConversation> create({
    required String mode,
    required String title,
    required List<ChatMessage> messages,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final now = DateTime.now().toUtc();

    final data = await _client
        .from(_table)
        .insert({
          'user_id': userId,
          'mode': mode,
          'title': title,
          'messages': messages.map((m) => m.toJson()).toList(),
          'last_message_at': now.toIso8601String(),
        })
        .select()
        .single();

    return AiConversation.fromJson(data);
  }

  /// Appends new messages and bumps [last_message_at] on an existing record.
  static Future<AiConversation> update({
    required String id,
    required List<ChatMessage> messages,
  }) async {
    final now = DateTime.now().toUtc();

    final data = await _client
        .from(_table)
        .update({
          'messages': messages.map((m) => m.toJson()).toList(),
          'last_message_at': now.toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();

    return AiConversation.fromJson(data);
  }

  /// Deletes every persisted AI conversation belonging to the signed-in user.
  static Future<void> clearAll() async {
    final userId = _client.auth.currentUser!.id;
    await _client.from(_table).delete().eq('user_id', userId);
  }
}
