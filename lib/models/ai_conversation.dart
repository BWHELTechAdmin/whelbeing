import '../services/ai_service.dart';

class AiConversation {
  final String id;
  final String userId;
  final String mode;
  final String title;
  final List<ChatMessage> messages;
  final DateTime lastMessageAt;
  final DateTime createdAt;

  const AiConversation({
    required this.id,
    required this.userId,
    required this.mode,
    required this.title,
    required this.messages,
    required this.lastMessageAt,
    required this.createdAt,
  });

  /// Resolves the [AiMode] enum from the stored mode string.
  AiMode get aiMode => AiMode.values.firstWhere(
        (m) => m.id == mode,
        orElse: () => AiMode.symptomNavigator,
      );

  factory AiConversation.fromJson(Map<String, dynamic> json) {
    return AiConversation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mode: json['mode'] as String,
      title: json['title'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((m) => ChatMessage(
                role: m['role'] as String,
                content: m['content'] as String,
              ))
          .toList(),
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'mode': mode,
        'title': title,
        'messages': messages.map((m) => m.toJson()).toList(),
        'last_message_at': lastMessageAt.toIso8601String(),
      };

  AiConversation copyWith({
    List<ChatMessage>? messages,
    DateTime? lastMessageAt,
  }) {
    return AiConversation(
      id: id,
      userId: userId,
      mode: mode,
      title: title,
      messages: messages ?? this.messages,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt,
    );
  }
}
