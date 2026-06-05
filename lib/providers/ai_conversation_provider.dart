import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_conversation.dart';
import '../repositories/ai_conversation_repository.dart';

/// Holds the loaded conversations and whether more pages exist.
class AiConversationsState {
  final List<AiConversation> conversations;
  final bool hasMore;

  const AiConversationsState({
    required this.conversations,
    required this.hasMore,
  });

  AiConversationsState copyWith({
    List<AiConversation>? conversations,
    bool? hasMore,
  }) {
    return AiConversationsState(
      conversations: conversations ?? this.conversations,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class AiConversationsNotifier
    extends AsyncNotifier<AiConversationsState> {
  int _page = 0;
  bool _loadingMore = false;

  @override
  Future<AiConversationsState> build() async {
    _page = 0;
    _loadingMore = false;
    final items = await AiConversationRepository.fetchPage(0);
    return AiConversationsState(
      conversations: items,
      hasMore: items.length >= AiConversationRepository.pageSize,
    );
  }

  /// Fetches the next page and appends to the current list.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || _loadingMore) return;

    _loadingMore = true;
    final next = _page + 1;
    try {
      final more = await AiConversationRepository.fetchPage(next);
      _page = next;
      state = AsyncData(AiConversationsState(
        conversations: [...current.conversations, ...more],
        hasMore: more.length >= AiConversationRepository.pageSize,
      ));
    } finally {
      _loadingMore = false;
    }
  }

  /// Inserts a new conversation at the top, or updates an existing one in-place,
  /// then re-sorts by [lastMessageAt] descending.
  void upsertLocal(AiConversation conversation) {
    final current = state.valueOrNull;
    if (current == null) return;

    final list = [...current.conversations];
    final idx = list.indexWhere((c) => c.id == conversation.id);
    if (idx >= 0) {
      list[idx] = conversation;
    } else {
      list.insert(0, conversation);
    }
    list.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

    state = AsyncData(current.copyWith(conversations: list));
  }
}

final aiConversationsProvider =
    AsyncNotifierProvider<AiConversationsNotifier, AiConversationsState>(
  AiConversationsNotifier.new,
);
